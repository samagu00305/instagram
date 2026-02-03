; 인스타그램 이벤트 자동화 프로그램

; 파일 인코딩 설정 (한글 깨짐 방지) - 반드시 최상단에 위치
FileEncoding, UTF-8

#Include GlobalData.ahk
#Include Util.ahk

; GUI 생성
Gui, Add, Text, x30 y5 w200 h20, 인스타그램 이벤트 자동화
Gui, Add, Text, x60 y25 w150 h20 vStatus, 대기 중...
Gui, Add, Text, x30 y50 w400 h30 vCommentCount, 오늘 댓글: 0개
Gui, Add, Text, x30 y80 w400 h30 vProgress, 진행 상태 표시
Gui, Add, Text, x30 y110 w400 h20 vWarmupInfo,
Gui, Add, Button, x20 y140 w90 h30 gButtonTestNormal, 시작
Gui, Add, Text, x20 y175 w90 h20 Center, (작업 실행)
Gui, Add, Button, x20 y210 w90 h30 gButtonTestNoSleep, 테스트 시작
Gui, Add, Text, x20 y245 w90 h20 Center, (수면시간 무시)
Gui, Add, Button, x120 y140 w90 h30 gButtonStop, 작업 중지
Gui, Add, Text, x120 y175 w90 h20 Center, (진행 중단)
Gui, Add, Button, x120 y210 w90 h30 gButtonTestComment, 댓글 테스트
Gui, Add, Text, x120 y245 w90 h20 Center, (조건무시 댓글)

; 워밍업이 활성화되어 있을 때만 워밍업 버튼 표시
if (g_WarmupEnabled())
{
    Gui, Add, Button, x220 y140 w90 h30 gButtonWarmup, 워밍업 시작
    Gui, Add, Text, x220 y175 w90 h20 Center, (시작일 설정)
    Gui, Add, Button, x320 y140 w90 h30 gButtonExit, 종료
    Gui, Add, Text, x320 y175 w90 h20 Center, (프로그램 종료)
}
else
{
    Gui, Add, Button, x220 y140 w90 h30 gButtonExit, 종료
    Gui, Add, Text, x220 y175 w90 h20 Center, (프로그램 종료)
}

; 전역 변수 - 수면 시간 체크 건너뛰기 플래그
global g_SkipSleepTimeCheck := false
; 전역 변수 - 테스트 모드 플래그 (모든 조건 검사 통과)
global g_TestMode := false

; 자동 워밍업 체크
CheckAutoWarmup()

; 워밍업 정보 표시
if (g_WarmupEnabled())
{
    if (IsWarmupActive())
    {
        ; 워밍업 중 - 시작일과 현재 일차 표시
        warmupDay := GetWarmupDay()
        warmupStartDate := GetWarmupStartDate()
        GuiControl,, WarmupInfo, [워밍업 D+%warmupDay%일차] 시작일: %warmupStartDate%
    }
    else
    {
        ; 워밍업 활성화되어 있지만 시작 안 함
        GuiControl,, WarmupInfo, [워밍업 미시작] '워밍업 시작' 버튼을 눌러 시작하세요
    }
}
else
{
    ; 워밍업 비활성화 - 아무것도 표시 안 함
    GuiControl,, WarmupInfo,
}

; 현재 댓글 개수 및 워밍업 상태 표시
currentCount := GetTodayCommentCount()
limit := GetWarmupTodayLimit()

if (IsWarmupActive())
{
    warmupDay := GetWarmupDay()
    percent := GetWarmupDayPercent(warmupDay)
    GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %currentCount%/%limit%개, %percent%`%)
}
else
{
    GuiControl,, CommentCount, 오늘 댓글: %currentCount%/%limit%개
}

Gui, Show, w420 h280, 인스타그램 자동화

isRunning := false
retryCount := 0

; ESC 키로 작업 중지 (프로그램 창이 활성화되어 있을 때만)
#IfWinActive, 인스타그램 자동화
    ~Esc::
        {
            if (isRunning)
            {
                Gosub, ButtonStop
            }
            return
        }
#IfWinActive

; Ctrl+Shift+Q 로 작업 중지 (전역 - 어디서든 작동)
^+q::
    {
        if (isRunning)
        {
            Gosub, ButtonStop
        }
        return
    }

return

; 일반 시작 버튼 (수면 시간 체크 활성화)
ButtonTestNormal:
    {
        ; 수면 시간 체크 플래그 초기화
        g_SkipSleepTimeCheck := false
        Debug("일반 시작 - 수면 시간 체크 활성화")

        ; 일반 시작 버튼과 동일한 로직 실행
        Gosub, ButtonTest

        return
    }
return

; 홈 화면 이미지 클릭 테스트 버튼
ButtonTest:
    {
        if (isRunning)
        {
            MsgBox, 이미 실행 중입니다.
            return
        }

        ; 일일 한도 체크
        if (CheckDailyLimit())
        {
            currentCount := GetTodayCommentCount()
            limit := GetWarmupTodayLimit()

            if (IsWarmupActive())
            {
                warmupDay := GetWarmupDay()
                percent := GetWarmupDayPercent(warmupDay)
                limitMessage := "오늘 댓글 한도에 도달했습니다!`n`n워밍업 D+" . warmupDay . " (" . percent . "%)`n현재: " . currentCount . "개 / 한도: " . limit . "개`n`n크롬 창을 닫고 내일 다시 시도해주세요."

                TelegramSend("🚫 일일 댓글 한도 도달!" . "`n" . "워밍업 D+" . warmupDay . " (" . percent . "%)" . "`n" . "오늘: " . currentCount . "개 / 한도: " . limit . "개" . "`n" . "크롬 창을 닫습니다.")
            }
            else
            {
                limitMessage := "오늘 댓글 한도에 도달했습니다!`n`n현재: " . currentCount . "개 / 한도: " . limit . "개`n`n크롬 창을 닫고 내일 다시 시도해주세요."

                TelegramSend("🚫 일일 댓글 한도 도달!" . "`n" . "오늘: " . currentCount . "개 / 한도: " . limit . "개" . "`n" . "크롬 창을 닫습니다.")
            }

            MsgBox, %limitMessage%

            ; 크롬 창 닫기
            Debug("일일 한도 도달 - 크롬 창 닫기")
            WinClose, ahk_exe chrome.exe

            Debug("일일 한도 도달 - 작업 시작 불가")
            return
        }

        isRunning := true
        retryCount := 0

        ; 새 세션 시작
        SaveSessionStartTime()

        ; 현재 댓글 개수 표시
        currentCount := GetTodayCommentCount()
        limit := GetWarmupTodayLimit()

        if (IsWarmupActive())
        {
            warmupDay := GetWarmupDay()
            percent := GetWarmupDayPercent(warmupDay)
            GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %currentCount%/%limit%개, %percent%`%)
            GuiControl,, Progress, 작업 시작!
            Debug("작업 시작 - 워밍업 D+" . warmupDay . " - 현재 댓글: " . currentCount . "/" . limit . "개")

            ; 텔레그램 알림
            TelegramSend("📈 워밍업 D+" . warmupDay . "`n" . "오늘 한도: " . limit . "개 (" . percent . "%)")
        }
        else
        {
            GuiControl,, CommentCount, 오늘 댓글: %currentCount%/%limit%개
            GuiControl,, Progress, 작업 시작!
            Debug("작업 시작 - 현재 댓글: " . currentCount . "/" . limit . "개")
        }

        ; 재시도 포인트 - 여기서부터 반복
        RetryPoint:
        retryCount++

        ; 팔로우 상태 초기화 (매 게시물마다 새롭게 확인)
        global g_AlreadyFollowed := false

        ; 중지 요청 확인
        if (!isRunning)
        {
            GuiControl,, Status, 중지됨
            GuiControl,, Progress, 작업이 중지되었습니다.
            Debug("작업 루프 종료 - isRunning = false")
            return
        }

        ; 일일 한도 체크 (작업 중에도 확인)
        if (CheckDailyLimit())
        {
            currentCount := GetTodayCommentCount()
            limit := GetWarmupTodayLimit()

            GuiControl,, Status, 한도 도달

            if (IsWarmupActive())
            {
                warmupDay := GetWarmupDay()
                percent := GetWarmupDayPercent(warmupDay)
                GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %currentCount%/%limit%개, %percent%`%)
                GuiControl,, Progress, 한도 도달! 크롬 창을 닫습니다...

                TelegramSend("🚫 일일 댓글 한도 도달!" . "`n" . "워밍업 D+" . warmupDay . " (" . percent . "%)" . "`n" . "오늘: " . currentCount . "개 / 한도: " . limit . "개" . "`n" . "크롬 창을 닫습니다.")
            }
            else
            {
                GuiControl,, CommentCount, 오늘 댓글: %currentCount%/%limit%개
                GuiControl,, Progress, 한도 도달! 크롬 창을 닫습니다...

                TelegramSend("🚫 일일 댓글 한도 도달!" . "`n" . "오늘: " . currentCount . "개 / 한도: " . limit . "개" . "`n" . "크롬 창을 닫습니다.")
            }

            Debug("일일 한도 도달 - 작업 중지")

            ; 크롬 창 닫기
            Sleep, 2000  ; 2초 대기 후 닫기
            Debug("크롬 창 닫기 시작")
            WinClose, ahk_exe chrome.exe

            isRunning := false
            return
        }

        ; 시간대별 활동 패턴 체크 (0% 시간대만 체크 - 수면 시간)
        ; g_SkipSleepTimeCheck가 true이면 수면 시간 체크를 건너뜀
        if (g_TimeBasedActivityEnabled() && !g_SkipSleepTimeCheck)
        {
            FormatTime, currentHour, , HH
            currentHour := currentHour + 0
            probability := GetActivityProbabilityByHour(currentHour)

            ; 완전 비활성 시간대(0%)만 대기 - 수면 시간
            if (probability = 0)
            {
                GuiControl,, Status, 대기 중
                waitMinutes := GetMinutesUntilNextActiveTime()

                ; 랜덤 오프셋 추가 (-30분 ~ +60분) - 매일 같은 시간에 시작하지 않도록
                Random, randomOffset, -30, 60
                waitMinutes := waitMinutes + randomOffset
                if (waitMinutes < 0)
                    waitMinutes := 0

                ; 재개 예정 시각 계산
                resumeTime := A_Now
                resumeTime += waitMinutes, Minutes
                FormatTime, resumeTimeFormatted, %resumeTime%, HH:mm:ss

                Debug("수면 시간대 - " . waitMinutes . "분 후 재개 (랜덤 오프셋: " . randomOffset . "분, 재개 예정: " . resumeTimeFormatted . ")")

                ; 텔레그램 알림
                TelegramSend("💤 수면 시간대 (" . currentHour . "시)" . "`n" . "약 " . waitMinutes . "분 후 재개됩니다." . "`n" . "재개 예정: " . resumeTimeFormatted)

                ; 초 단위 카운트다운
                waitSeconds := waitMinutes * 60
                Loop, %waitSeconds%
                {
                    if (!isRunning)
                    {
                        GuiControl,, Status, 중지됨
                        GuiControl,, Progress, 작업이 중지되었습니다.
                        Debug("수면 시간대 대기 중 작업 중지됨")
                        return
                    }

                    remainingSeconds := waitSeconds - A_Index + 1

                    ; 시:분:초로 표시
                    if (remainingSeconds >= 3600)
                    {
                        remainingHours := Floor(remainingSeconds / 3600)
                        remainingMinutesOnly := Floor(Mod(remainingSeconds, 3600) / 60)
                        remainingSecondsOnly := Mod(remainingSeconds, 60)
                        GuiControl,, Progress, 수면 시간대입니다... (남은 시간: %remainingHours%시간 %remainingMinutesOnly%분 %remainingSecondsOnly%초)
                    }
                    else
                    {
                        remainingMinutesDisplay := Floor(remainingSeconds / 60)
                        remainingSecondsOnly := Mod(remainingSeconds, 60)
                        GuiControl,, Progress, 수면 시간대입니다... (남은 시간: %remainingMinutesDisplay%분 %remainingSecondsOnly%초)
                    }

                    Sleep, 1000  ; 1초 대기
                }

                Debug("수면 시간대 대기 완료 - 작업 재개")

                ; 수면 대기 후 새 세션 시작 (세션 시간 리셋)
                SaveSessionStartTime()
                Debug("수면 대기 완료 - 새 세션 시작")

                GoTo, RetryPoint
            }
        }

        ; 세션 시간 체크
        if (ShouldEndSession())
        {
            ; 세션 종료 - 휴식 필요
            GuiControl,, Status, 세션 종료

            ; 시간대별 휴식 시간 가져오기
            FormatTime, currentHour, , HH
            currentHour := currentHour + 0

            ; GlobalData에서 시간대별 설정 가져오기
            breakSettings := GetSessionBreakByHour(currentHour)
            StringSplit, breakParts, breakSettings, `,
            adjustedMin := breakParts1
            adjustedMax := breakParts2

            Random, breakMinutes, %adjustedMin%, %adjustedMax%
            Debug("시간대별 휴식 설정: " . currentHour . "시 → " . adjustedMin . "~" . adjustedMax . "분 범위에서 " . breakMinutes . "분 선택")

            ; 재개 예정 시각 계산
            resumeTime := A_Now
            resumeTime += breakMinutes, Minutes
            FormatTime, resumeTimeFormatted, %resumeTime%, HH:mm:ss

            GuiControl,, Progress, 세션 종료. %breakMinutes%분 후 재개...
            Debug("세션 종료 - " . breakMinutes . "분 휴식 (재개 예정: " . resumeTimeFormatted . ")")

            ; 텔레그램 알림
            TelegramSend("☕ 세션 종료" . "`n" . breakMinutes . "분 휴식 후 재개됩니다." . "`n" . "재개 예정: " . resumeTimeFormatted)

            ; 휴식 시간 대기 (초 단위로 카운트다운)
            breakSeconds := breakMinutes * 60
            Loop, %breakSeconds%
            {
                if (!isRunning)
                {
                    GuiControl,, Status, 중지됨
                    GuiControl,, Progress, 작업이 중지되었습니다.
                    Debug("휴식 중 작업 중지됨")
                    return
                }

                remainingSeconds := breakSeconds - A_Index + 1

                ; 분:초로 표시
                remainingMinutesDisplay := Floor(remainingSeconds / 60)
                remainingSecondsOnly := Mod(remainingSeconds, 60)
                GuiControl,, Progress, 세션 휴식 중... (남은 시간: %remainingMinutesDisplay%분 %remainingSecondsOnly%초)

                Sleep, 1000  ; 1초 대기
            }

            ; 휴식 완료 - 새 세션 시작
            SaveSessionStartTime()
            GuiControl,, Progress, 휴식 완료! 새 세션 시작...
            Debug("휴식 완료 - 새 세션 시작")
        }

        GuiControl,, Status, 실행 중...

        ; 재시도 패턴 결정 (1회차: 인스타 버튼 / 2,3,4,5,6,7회차: 스크롤 다운, 8회차: 인스타 버튼...)
        cycle := Mod(retryCount - 1, 7)

        if (cycle == 0)
        {
            ; 1회차, 8회차, 15회차...: 인스타그램 버튼 클릭 방식
            GuiControl,, Progress, 홈 화면 이미지를 찾는 중... (재시도 %retryCount%회)
            Debug("재시도 " . retryCount . "회 - 인스타그램 버튼 방식")

            ; 홈 화면 이미지 찾아서 클릭
            result := FindAndClickHomeImage()

            if (!result)
            {
                GuiControl,, Progress, 홈 화면 이미지를 찾을 수 없습니다.
                GuiControl,, Status, 실패
                Debug("홈 화면 이미지를 찾을 수 없습니다")
                MsgBox, 인스타그램 버튼 이미지를 찾을 수 없습니다.`n`nImage 폴더에 인스타그램 버튼 이미지를 추가해주세요.`n이미지 파일명: 인스타그램 버튼.png

                ; 텔레그램 알림
                TelegramSend("🚫 작업 중지됨" . "`n" . "인스타그램 버튼 이미지를 찾을 수 없습니다." . "`n" . "Image 폴더에 '인스타그램 버튼.png' 파일을 추가해주세요.")

                isRunning := false
                SleepTime(2)
                GuiControl,, Status, 대기 중...
                GuiControl,, Progress, 진행 상태 표시
                return
            }

            GuiControl,, Progress, 홈 화면 이미지 클릭 성공! 랜덤 대기 중...
            Debug("홈 화면 이미지 클릭 성공")

            ; 랜덤 딜레이 (기준: 5초)
            RandomDelay(5)
        }
        else
        {
            ; 2회차, 3회차, 4회차, 5회차, 6회차, 7회차, 9회차, 10회차...: 팝업 닫기 → 스크롤 다운 방식
            GuiControl,, Progress, 팝업 닫기 버튼을 찾는 중... (재시도 %retryCount%회)
            Debug("재시도 " . retryCount . "회 - 스크롤 다운 방식")

            ; 팝업 닫기 버튼 클릭
            popupResult := CloseInstagramPopup()

            if (popupResult)
            {
                GuiControl,, Progress, 팝업 닫기 성공! 2초 대기 중...
                Debug("팝업 닫기 버튼 클릭 성공")
            }
            else
            {
                GuiControl,, Progress, 팝업 닫기 버튼을 찾을 수 없음 (계속 진행)
                Debug("팝업 닫기 버튼을 찾을 수 없습니다 - 계속 진행")
            }

            ; 랜덤 딜레이 (기준: 2초)
            RandomDelay(2)

            ; 랜덤 스크롤 패턴으로 변경
            GuiControl,, Progress, 랜덤 스크롤 중...
            RandomScroll()

            ; 랜덤 딜레이 (기준: 3초)
            RandomDelay(3)
        }

        ; 여기서부터는 공통 로직: 좋아요 누른 상태 체크
        ; 게시물 확인 전 랜덤 행동
        RandomPause()

        GuiControl,, Progress, 좋아요 누른 상태 확인 중...
        likedStatus := CheckLikedStatus()

        if (likedStatus)
        {
            retryDelay := g_RetryDelaySeconds()
            GuiControl,, Status, 재시도 대기 중
            Debug("이미 좋아요 누른 게시물입니다. " . retryDelay . "초 후 재시도")

            ; 재시도 대기 (카운트다운)
            SleepWithCountdown(retryDelay, "이미 좋아요 누른 게시물입니다")

            ; 처음부터 다시 시작
            GoTo, RetryPoint
        }

        ; 좋아요 누른 상태가 아니면 댓글 버튼 찾기
        GuiControl,, Progress, 댓글 버튼을 찾는 중...
        commentResult := FindAndClickCommentButton()

        if (commentResult)
        {
            GuiControl,, Progress, 댓글 버튼 클릭 성공! 랜덤 대기 중...
            Debug("댓글 버튼 클릭 성공")

            ; 랜덤 딜레이 (기준: 3초)
            RandomDelay(3)

            ; 댓글 내용 읽는 척하기
            RandomReading()

            ; 전체 선택 및 복사 후 "좋아요 " 이후 부분만 추출
            GuiControl,, Progress, 내용 복사 및 처리 중...
            filterResult := CopyAndFilterAfterMeta()

            if (filterResult)
            {
                GuiControl,, Progress, 내용 복사 완료! 이벤트 판단 키워드 검증 중...
                Debug("내용 복사 및 필터링 완료")

                global g_LastFilteredContent

                ; 이벤트 판단 키워드 체크 (이벤트인지 먼저 확인)
                if (!CheckEventKeywords(g_LastFilteredContent))
                {
                    retryDelay := g_RetryDelaySeconds()
                    Debug("이벤트 판단 키워드 없음 - 이벤트 아님, 게시물 스킵")
                    SleepWithCountdown(retryDelay, "이벤트 키워드 없음")
                    GoTo, RetryPoint
                }

                GuiControl,, Progress, 이벤트 확인! 제외 키워드 검증 중...

                ; 제외 키워드 체크 (전체 처리 중단용)
                if (CheckBlacklist(g_LastFilteredContent))
                {
                    retryDelay := g_RetryDelaySeconds()
                    Debug("제외 키워드 발견 - 게시물 스킵")
                    SleepWithCountdown(retryDelay, "제외 키워드 발견")
                    GoTo, RetryPoint
                }

                GuiControl,, Progress, 제외 키워드 검증 통과! AI에게 질문 시작...

                ; AI에게 질문하고 답변 받기
                aiResult := AskAIAndGetResponse()

                if (aiResult = -1)
                {
                    ; "불가" 발견 - 재시도
                    retryDelay := g_RetryDelaySeconds()
                    Debug("참여 불가 - " . retryDelay . "초 후 재시도")
                    SleepWithCountdown(retryDelay, "참여 불가 게시물입니다")
                    GoTo, RetryPoint
                }
                else if (aiResult = 1)
                {
                    global g_AlreadyFollowed

                    GuiControl,, Progress, 댓글 게시 완료! 팔로우 상태 확인 중...
                    Debug("댓글 게시 완료")

                    ; 이미 팔로우 버튼을 클릭했는지 확인
                    if (g_AlreadyFollowed)
                    {
                        GuiControl,, Progress, 이미 팔로우 완료! 팔로우 프로세스 스킵...
                        Debug("이미 댓글 달기 전에 팔로우를 완료했으므로 팔로우 프로세스 스킵")

                        ; 팝업 닫기만 수행 (랜덤 대기 후)
                        RandomDelay(3)
                        GuiControl,, Progress, 팝업 닫기 버튼 클릭 중...
                        closePopupResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 닫기 버튼", 5, 1)

                        if (!closePopupResult)
                        {
                            Debug("팝업 닫기 버튼을 찾을 수 없습니다 - 계속 진행")
                        }
                        else
                        {
                            Debug("팝업 닫기 버튼 클릭 성공")
                        }

                        ; 대기 후 다음 게시물로 이동
                        RandomDelay(3)

                        ; 가끔 실수 행동 추가
                        RandomMistake()

                        GuiControl,, Progress, 작업 완료! 다음 댓글까지 대기...
                        GuiControl,, Status, 완료
                        Debug("작업 완료 - 성공 기반 간격 대기 시작")

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }

                        GoTo, RetryPoint
                    }

                    ; 팔로우가 필요한 경우 팔로우 프로세스 시작
                    GuiControl,, Progress, 팔로우 프로세스 시작...
                    Debug("팔로우 프로세스 시작")

                    ; 1. 팝업 닫기 (랜덤 대기 후)
                    RandomDelay(3)
                    GuiControl,, Progress, 팝업 닫기 버튼 클릭 중...
                    closePopupResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 닫기 버튼", 5, 1)

                    if (!closePopupResult)
                    {
                        Debug("팝업 닫기 버튼을 찾을 수 없습니다 - 계속 진행")
                    }
                    else
                    {
                        Debug("팝업 닫기 버튼 클릭 성공")
                    }

                    ; 2. 메뉴 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(2)
                    GuiControl,, Progress, 메뉴 버튼 클릭 중...
                    menuResult := ClickAtCenterWhileFoundImage("인스타그램 메뉴 버튼", 5, 1)

                    if (!menuResult)
                    {
                        Debug("메뉴 버튼을 찾을 수 없습니다 - 팔로우 프로세스 스킵")
                        GuiControl,, Progress, 팔로우 프로세스 실패 - 다음 댓글까지 대기...
                        GuiControl,, Status, 완료

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }
                        GoTo, RetryPoint
                    }

                    Debug("메뉴 버튼 클릭 성공")

                    ; 3. 내 활동 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(3)
                    GuiControl,, Progress, 내 활동 버튼 클릭 중...
                    activityResult := ClickAtCenterWhileFoundImage("인스타그램 내 활동 버튼", 5, 1)

                    if (!activityResult)
                    {
                        Debug("내 활동 버튼을 찾을 수 없습니다 - 팔로우 프로세스 스킵")
                        GuiControl,, Progress, 팔로우 프로세스 실패 - 다음 댓글까지 대기...
                        GuiControl,, Status, 완료

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }
                        GoTo, RetryPoint
                    }

                    Debug("내 활동 버튼 클릭 성공")

                    ; 4. 내 활동의 댓글 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(5)
                    GuiControl,, Progress, 내 활동의 댓글 버튼 클릭 중...
                    commentResult := ClickAtCenterWhileFoundImage("인스타그램 내 활동의 댓글 버튼", 5, 1)

                    if (!commentResult)
                    {
                        Debug("내 활동의 댓글 버튼을 찾을 수 없습니다 - 팔로우 프로세스 스킵")
                        GuiControl,, Progress, 팔로우 프로세스 실패 - 다음 댓글까지 대기...
                        GuiControl,, Status, 완료

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }
                        GoTo, RetryPoint
                    }

                    Debug("내 활동의 댓글 버튼 클릭 성공")

                    ; 5. 내 활동의 댓글의 내 그림 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(4)
                    GuiControl,, Progress, 내 그림 버튼 클릭 중...
                    myPicResult := ClickAtCenterWhileFoundImage("인스타그램 내 활동의 댓글의 내 그림 버튼", 5, 1)

                    if (!myPicResult)
                    {
                        Debug("내 그림 버튼을 찾을 수 없습니다 - 팔로우 프로세스 스킵")
                        GuiControl,, Progress, 팔로우 프로세스 실패 - 다음 댓글까지 대기...
                        GuiControl,, Status, 완료

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }
                        GoTo, RetryPoint
                    }

                    Debug("내 그림 버튼 클릭 성공")

                    ; 6. 내 활동의 팔로우 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(3)
                    GuiControl,, Progress, 팔로우 버튼 클릭 중...
                    followResult := FindAndClickFollowButton()

                    if (!followResult)
                    {
                        Debug("팔로우 버튼을 찾을 수 없습니다 - 이미 팔로우된 상태일 수 있음, 계속 진행")
                        GuiControl,, Progress, 팔로우 버튼을 찾을 수 없음 (이미 팔로우됨?) - 계속 진행
                    }
                    else
                    {
                        Debug("팔로우 버튼 클릭 성공")
                    }

                    ; 7. 홈 버튼 클릭 (랜덤 대기 후)
                    RandomDelay(3)
                    GuiControl,, Progress, 홈 버튼 클릭 중...
                    homeResult := ClickAtCenterWhileFoundImage("인스타그램 홈 버튼", 5, 1)

                    if (!homeResult)
                    {
                        Debug("홈 버튼을 찾을 수 없습니다 - 팔로우 프로세스 스킵")
                        GuiControl,, Progress, 팔로우 프로세스 실패 - 다음 댓글까지 대기...
                        GuiControl,, Status, 완료

                        ; 성공 기반 간격 대기
                        if (!WaitAfterSuccess())
                        {
                            ; 대기 중 중지됨
                            return
                        }
                        GoTo, RetryPoint
                    }

                    Debug("홈 버튼 클릭 성공")

                    ; 8. 마지막 대기 후 다음 게시물로 이동
                    RandomDelay(3)

                    ; 가끔 실수 행동 추가 (더 자연스럽게)
                    RandomMistake()

                    GuiControl,, Progress, 팔로우 프로세스 완료! 다음 댓글까지 대기...
                    GuiControl,, Status, 완료
                    Debug("팔로우 프로세스 완료 - 성공 기반 간격 대기 시작")

                    ; 성공 기반 간격 대기
                    if (!WaitAfterSuccess())
                    {
                        ; 대기 중 중지됨
                        return
                    }

                    GoTo, RetryPoint
                }
                else
                {
                    ; AI 처리 실패 - 재시도
                    retryDelay := g_RetryDelaySeconds()
                    GuiControl,, Status, 오류 - 재시도 대기 중
                    Debug("AI 처리 실패 - " . retryDelay . "초 후 재시도")
                    SleepWithCountdown(retryDelay, "AI 처리 중 오류 발생")
                    GoTo, RetryPoint
                }
            }
            else
            {
                ; "좋아요 " 텍스트를 찾지 못함 - 재시도
                retryDelay := g_RetryDelaySeconds()
                GuiControl,, Status, 재시도 대기 중
                Debug("좋아요 텍스트를 찾을 수 없습니다. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "좋아요 텍스트를 찾을 수 없습니다")
                GoTo, RetryPoint
            }
        }
        else
        {
            retryDelay := g_RetryDelaySeconds()
            GuiControl,, Status, 재시도 대기 중
            Debug("댓글 버튼을 찾을 수 없습니다. " . retryDelay . "초 후 재시도")

            ; 재시도 대기 (카운트다운)
            SleepWithCountdown(retryDelay, "댓글 버튼을 찾을 수 없습니다")

            ; 처음부터 다시 시작
            GoTo, RetryPoint
        }
    }
return

; 테스트 시작 버튼 (수면 시간 무시)
ButtonTestNoSleep:
    {
        ; 수면 시간 체크 건너뛰기 플래그 설정
        g_SkipSleepTimeCheck := true
        Debug("테스트 시작 - 수면 시간 체크 건너뜀")

        ; 일반 시작 버튼과 동일한 로직 실행
        Gosub, ButtonTest

        return
    }
return

; 작업 중지 버튼
ButtonStop:
    {
        if (isRunning)
        {
            isRunning := false
            GuiControl,, Status, 중지됨
            GuiControl,, Progress, 작업이 사용자에 의해 중지되었습니다.
            Debug("작업 중지 - 사용자 요청")

            ; 수면 시간 체크 플래그 초기화
            g_SkipSleepTimeCheck := false

            ; 텔레그램 알림
            currentCount := GetTodayCommentCount()
            limit := GetWarmupTodayLimit()
            TelegramSend("⏹️ 작업이 중지되었습니다." . "`n" . "오늘 댓글: " . currentCount . "/" . limit . "개")
        }
        else
        {
            GuiControl,, Progress, 실행 중인 작업이 없습니다.
        }
        return
    }
return

; 워밍업 시작 버튼
ButtonWarmup:
    {
        if (isRunning)
        {
            MsgBox, 작업 실행 중에는 워밍업을 시작할 수 없습니다.
            return
        }

        result := StartWarmup()
        if (result)
        {
            MsgBox, 워밍업이 시작되었습니다!

            ; GUI 업데이트
            currentCount := GetTodayCommentCount()
            limit := GetWarmupTodayLimit()
            warmupDay := GetWarmupDay()
            percent := GetWarmupDayPercent(warmupDay)
            warmupStartDate := GetWarmupStartDate()

            GuiControl,, WarmupInfo, [워밍업 D+%warmupDay%일차] 시작일: %warmupStartDate%
            GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %currentCount%/%limit%개, %percent%`%)
        }
        else
        {
            MsgBox, 워밍업 시작에 실패했습니다.
        }
        return
    }
return

; 댓글 테스트 버튼 (조건 무시하고 바로 댓글 달기)
ButtonTestComment:
    {
        global g_TestMode, g_SkipSleepTimeCheck

        ; 테스트 모드 활성화 (모든 조건 검사 통과)
        g_TestMode := true
        g_SkipSleepTimeCheck := true

        Debug("===== 댓글 테스트 모드 시작 (조건 무시) =====")

        ; 기존 작업 시작 로직 실행
        GoSub, ButtonTest

        ; 테스트 모드 종료
        g_TestMode := false
        g_SkipSleepTimeCheck := false

        Debug("===== 댓글 테스트 모드 종료 =====")
    }
return

; 종료 버튼
ButtonExit:
    {
        ExitApp
    }
return

; GUI 닫기
GuiClose:
    {
        ExitApp
    }
return

; ==========================================
; 메인 로직 함수들
; ==========================================

; 홈 화면 이미지 찾아서 클릭
FindAndClickHomeImage()
{
    ; Image 폴더에 있는 인스타그램 버튼.png 이미지를 찾아서 클릭
    ; 이미지 경로: Image\인스타그램 버튼.png
    imagePath := "인스타그램 버튼"

    Debug("홈 화면 이미지 검색 시작: " . imagePath)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath, 5, 1)

    return result
}

; 인스타그램 팝업 닫기 버튼 클릭
CloseInstagramPopup()
{
    imagePath := "인스타그램 팝업 닫기 버튼"

    Debug("인스타그램 팝업 닫기 버튼 검색 시작: " . imagePath)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath, 5, 1)

    return result
}

; 댓글 버튼 이미지 찾아서 클릭
FindAndClickCommentButton()
{
    ; Image 폴더에 있는 "댓글 버튼1.png" 이미지를 먼저 찾아서 클릭
    imagePath1 := "댓글 버튼1"

    Debug("댓글 버튼1 이미지 검색 시작: " . imagePath1)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath1, 5, 1)

    if (result)
    {
        return true
    }

    ; 댓글 버튼1을 찾지 못했으면 댓글 버튼2 찾기
    imagePath2 := "댓글 버튼2"

    Debug("댓글 버튼1을 찾지 못했습니다. 댓글 버튼2 이미지 검색 시작: " . imagePath2)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath2, 5, 1)

    return result
}

; 팔로우 버튼 이미지 찾아서 클릭
FindAndClickFollowButton()
{
    ; Image 폴더에 있는 "인스타그램 내 활동의 팔로우 버튼1.png" 이미지를 먼저 찾아서 클릭
    imagePath1 := "인스타그램 내 활동의 팔로우 버튼1"

    Debug("팔로우 버튼1 이미지 검색 시작: " . imagePath1)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath1, 5, 1)

    if (result)
    {
        return true
    }

    ; 팔로우 버튼1을 찾지 못했으면 팔로우 버튼2 찾기
    imagePath2 := "인스타그램 내 활동의 팔로우 버튼2"

    Debug("팔로우 버튼1을 찾지 못했습니다. 팔로우 버튼2 이미지 검색 시작: " . imagePath2)

    ; 최대 5번, 1초 간격으로 이미지를 찾아서 중앙 클릭 시도
    result := ClickAtCenterWhileFoundImage(imagePath2, 5, 1)

    return result
}

; "좋아요 누른 상태" 이미지 확인 (딱 한번만 체크)
CheckLikedStatus()
{
    global g_TestMode

    ; 테스트 모드일 때는 무조건 좋아요 안 누른 상태로 처리
    if (g_TestMode)
    {
        Debug("[테스트 모드] 좋아요 상태 검사 스킵 - 무조건 새 게시물로 처리")
        return false
    }

    ; Image 폴더에 있는 "좋아요 누른 상태.png" 이미지가 있는지 확인
    imagePath := "좋아요 누른 상태"

    Debug("좋아요 누른 상태 이미지 확인: " . imagePath)

    ; 이미지 존재 여부만 확인 (한번만)
    result := IsImageExist(imagePath)

    if (result)
    {
        Debug("좋아요 누른 상태 이미지 발견!")
    }
    else
    {
        Debug("좋아요 누른 상태 이미지 없음 - 새로운 게시물")
    }

    return result
}

; 전체 내용 복사 후 "좋아요 " 이후 부분만 클립보드에 남기기
CopyAndFilterAfterMeta()
{
    global g_LastFilteredContent

    ; 클립보드 초기화
    Clipboard := ""

    ; 1. "인스타그램 팝업 닫기 버튼" 이미지 찾기
    imagePath := A_ScriptDir . "\Image\인스타그램 팝업 닫기 버튼.png"
    ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath%

    if (ErrorLevel)
    {
        Debug("팝업 닫기 버튼을 찾을 수 없어 기존 방식 사용")
        ; 기존 방식으로 폴백
        Send, ^a
        RandomDelay(0.5)
        Send, ^c
        RandomDelay(0.5)
    }
    else
    {
        ; 2. 화면 왼쪽(10), 닫기 버튼 Y좌표 + 50 위치에서 드래그 시작
        startX := 10
        startY := foundY + 50
        endX := foundX
        endY := A_ScreenHeight

        Debug("드래그 선택: (" . startX . ", " . startY . ") → (" . endX . ", " . endY . ")")

        ; 3. 마우스 드래그로 선택
        MouseMove, %startX%, %startY%
        RandomDelay(0.3)
        Click, down
        RandomDelay(0.2)
        MouseMove, %endX%, %endY%
        RandomDelay(0.2)
        Click, up
        RandomDelay(0.3)

        ; 4. Ctrl+C로 복사
        Send, ^c
        Debug("복사 (Ctrl+C)")
        RandomDelay(0.5)
    }

    ; 클립보드 내용 확인
    ClipWait, 2
    if ErrorLevel
    {
        Debug("클립보드 복사 실패")
        return false
    }

    copiedText := Clipboard
    Debug("복사된 내용 길이: " . StrLen(copiedText))

    ; "좋아요 " 텍스트 찾기
    searchText := "좋아요 "
    foundPos := InStr(copiedText, searchText)

    if (foundPos = 0)
    {
        Debug("'좋아요 ' 텍스트를 찾을 수 없습니다")
        return false
    }

    ; "좋아요 " 이후 부분 추출 (검색 텍스트 길이만큼 뒤로 이동)
    afterPos := foundPos + StrLen(searchText)
    filteredText := SubStr(copiedText, afterPos)

    ; 전역 변수에 저장 (수동 참여 키워드 체크용)
    g_LastFilteredContent := filteredText

    ; 파일에서 프롬프트 읽기
    additionalText := LoadPromptFromFile("data\AI게시글판단_프롬프트.txt")

    ; 파일을 읽지 못한 경우 빈 문자열
    if (additionalText = "")
    {
        Debug("프롬프트 파일 로드 실패 - 빈 문자열 사용")
    }

    ; 클립보드에 필터링된 텍스트 + 추가 텍스트 저장
    Clipboard := filteredText . "`n`n" . additionalText
    Debug("필터링된 내용 길이: " . StrLen(filteredText))
    Debug("클립보드에 '좋아요 ' 이후 내용 + 추가 텍스트 저장 완료")

    return true
}

; 인스타그램 앱 실행 (추후 구현)
LaunchInstagram()
{
    ; 인스타그램 앱을 실행하는 로직
    ; 안드로이드 에뮬레이터나 실제 기기에서 실행
    Debug("인스타그램 앱 실행")
}

; 홈 화면으로 이동 (추후 구현)
GoToHome()
{
    ; 홈 화면으로 이동하는 로직
    Debug("홈 화면으로 이동")
}

; AI에게 질문하고 답변 받기 - WRTN AI (뤼튼) 버전
AskAIAndGetResponse_WRTN()
{
    global g_AlreadyFollowed

    ; 1. Ctrl+T로 새 탭 열기
    Debug("Ctrl+T로 새 탭 열기")
    Send, ^t
    RandomDelay(1.5)

    ; 2. "WRTN 실행 버튼" 이미지 찾아서 클릭
    GuiControl,, Progress, WRTN AI 실행 버튼 찾는 중...
    Debug("WRTN AI 실행 버튼 이미지 검색 시작")
    wrtnButtonResult := ClickAtCenterWhileFoundImage("WRTN 실행 버튼", 5, 1)

    if (!wrtnButtonResult)
    {
        Debug("WRTN 실행 버튼을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return false
    }

    Debug("WRTN 실행 버튼 클릭 성공")
    RandomDelay(3)  ; 페이지 로딩 대기

    ; 2. "무엇이든 물어보세요" 입력창 클릭
    GuiControl,, Progress, WRTN 입력창 찾는 중...
    Debug("WRTN 입력창 이미지 검색 시작")
    inputBoxResult := ClickAtCenterWhileFoundImage("WRTN 입력창", 5, 1)

    if (!inputBoxResult)
    {
        Debug("WRTN 입력창을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return false
    }

    Debug("WRTN 입력창 클릭 성공")
    RandomDelay(0.5)

    ; 4. Ctrl+V로 붙여넣기
    GuiControl,, Progress, 내용 붙여넣기 중...
    Debug("Ctrl+V로 붙여넣기")
    Send, ^v
    RandomDelay(1)

    ; 5. Enter 키 입력
    Debug("Enter 키 입력")
    Send, {Enter}

    ; 6. 2초 대기 후 클릭 + End
    RandomDelay(2)
    Debug("마우스 클릭")
    Click
    RandomDelay(0.5)
    Debug("End 키로 스크롤 맨 아래로 이동")
    Send, {End}
    RandomDelay(1)

    ; 7. AI 답변 대기 (최대 10초, 2초마다 복사 버튼 체크)
    GuiControl,, Progress, WRTN AI 답변 대기 중...
    Debug("WRTN AI 답변 대기 시작 - 2초마다 체크")

    found := false
    imagePath := A_ScriptDir . "\Image\AI 답변 내용 복사 버튼 WRTN.png"

    Loop, 5
    {
        RandomDelay(2)

        ; 이미지 찾기 (클릭하지 않음)
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath%

        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("WRTN AI 답변 복사 버튼 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }
    }

    if (!found)
    {
        Debug("최대 대기 시간(10초) 경과 - 복사 버튼 최종 검색")
    }

    ; 8. "AI 답변 내용 복사 버튼 WRTN" 이미지 찾아서 클릭
    GuiControl,, Progress, WRTN AI 답변 복사 버튼 찾는 중...
    Debug("WRTN AI 답변 내용 복사 버튼 이미지 검색 시작")
    copyButtonResult := ClickAtCenterWhileFoundImage("AI 답변 내용 복사 버튼 WRTN", 10, 2)

    if (!copyButtonResult)
    {
        Debug("WRTN AI 답변 내용 복사 버튼을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return false
    }

    Debug("WRTN AI 답변 내용 복사 버튼 클릭 성공")
    RandomDelay(1)

    ; 8. 클립보드 내용 확인 (AI 답변)
    ClipWait, 2
    if ErrorLevel
    {
        Debug("클립보드 복사 실패")
        Send, ^w  ; 탭 닫기
        return false
    }

    aiResponse := Clipboard

    ; 출처 링크 완전히 제거: [1](https://...) -> 삭제
    aiResponse := RegExReplace(aiResponse, "\[(\d+)\]\(https?://[^\)]+\)", "")

    ; 끝부분의 빈 줄 제거
    aiResponse := RTrim(aiResponse, " `t`r`n")

    Debug("WRTN AI 답변 길이: " . StrLen(aiResponse))

    ; 9. AI 답변 분석 (이하 Perplexity와 동일)
    global g_LastFilteredContent, g_TestMode

    ; 테스트 모드일 때는 AI 답변 분석 스킵하고 무조건 바로 참여 가능으로 처리
    if (g_TestMode)
    {
        Debug("[테스트 모드] AI 답변 분석 스킵 - 무조건 바로 참여 가능으로 처리")
        isExcluded := false
        isDirectParticipation := true
        isOngoing := true
        isFormRequired := false
    }
    else
    {
        isExcluded := (InStr(aiResponse, "제외 판단 - 예") > 0 || InStr(aiResponse, "제외 판단-예") > 0)
        isDirectParticipation := (InStr(aiResponse, "바로 참여 여부 - 가능") > 0 || InStr(aiResponse, "바로 참여 여부-가능") > 0)
        isOngoing := (InStr(aiResponse, "진행중") > 0)

        ; 수동 참여 필요 여부는 게시물 내용에서 키워드 매칭으로 판단
        isFormRequired := CheckManualParticipationKeywords(g_LastFilteredContent)
    }

    ; 9-1. 제외 판단이 예이면 관심 없음 처리 후 스킵
    if (isExcluded)
    {
        Debug("제외 판단 - 관심 없음 처리 시작")
        Send, ^w  ; AI 탭 닫기
        RandomDelay(0.5)

        ; 1. 인스타그램 팝업 메뉴 버튼 클릭
        popupMenuResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 메뉴 버튼", 5, 1)
        if (popupMenuResult)
        {
            Debug("인스타그램 팝업 메뉴 버튼 클릭 성공")
            RandomDelay(2)

            ; 2. 관심 없음 버튼 클릭
            notInterestedResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 메뉴 관심 없음", 5, 1)
            if (notInterestedResult)
            {
                Debug("관심 없음 클릭 성공")
                RandomDelay(1)
            }
            else
            {
                Debug("관심 없음 버튼을 찾을 수 없음 - ESC로 닫기")
                Send, {Escape}
                RandomDelay(0.5)
            }
        }
        else
        {
            Debug("팝업 메뉴 버튼을 찾을 수 없음 - 스킵")
        }

        return -1
    }

    ; 9-2. 바로 참여 가능하면 댓글 달기 진행
    if (isDirectParticipation)
    {
        Debug("바로 참여 가능 - 댓글 달기 진행")
        ; 아래에서 계속 진행됨
    }
    else
    {
        ; 9-3. 바로 참여 불가 + 수동 참여 필요 + 진행중 → 텔레그램 전송
        if (isFormRequired && isOngoing)
        {
            ; 수동 참여 알림이 비활성화되어 있으면 건너뛰기
            global MANUAL_PARTICIPATION_ALERT_ENABLED
            if (MANUAL_PARTICIPATION_ALERT_ENABLED = "false" || MANUAL_PARTICIPATION_ALERT_ENABLED = "0")
            {
                Debug("수동 참여 알림 비활성화 상태 - 스킵")
                Send, ^w
                return -1
            }

            Debug("바로 참여 불가 + 수동 참여 필요 이벤트 발견 - 텔레그램 알림 시작")

            ; AI 탭을 먼저 닫아서 인스타그램 화면이 보이도록 함
            Send, ^w
            RandomDelay(0.5)
            Debug("WRTN AI 탭 닫기 완료 - 인스타그램 화면으로 전환")

            ; 1. "인스타그램 팝업 메뉴 버튼" 클릭
            GuiControl,, Progress, 인스타그램 팝업 메뉴 버튼 클릭 중...
            popupMenuResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 메뉴 버튼", 5, 1)

            if (!popupMenuResult)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("인스타그램 팝업 메뉴 버튼을 찾을 수 없습니다. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "인스타그램 팝업 메뉴 버튼을 찾을 수 없습니다")
                return -1
            }

            Debug("인스타그램 팝업 메뉴 버튼 클릭 성공")
            RandomDelay(2)

            ; 2. "인스타그램 팝업 링크복사 버튼" 클릭
            GuiControl,, Progress, 링크 복사 버튼 클릭 중...
            linkCopyResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 링크복사 버튼", 5, 1)

            if (!linkCopyResult)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("인스타그램 팝업 링크복사 버튼을 찾을 수 없습니다. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "인스타그램 팝업 링크복사 버튼을 찾을 수 없습니다")
                return -1
            }

            Debug("인스타그램 팝업 링크복사 버튼 클릭 성공")
            RandomDelay(1)

            ; 3. 클립보드에서 링크 가져오기
            ClipWait, 2
            if (ErrorLevel)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("링크 복사 실패. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "링크 복사 실패")
                return -1
            }

            copiedLink := Clipboard
            Debug("링크 복사 완료: " . copiedLink)

            ; 4. 수동 참여 제외 키워드 체크
            global g_LastFilteredContent
            if (CheckManualParticipationBlacklist(g_LastFilteredContent))
            {
                GuiControl,, Progress, 수동 참여 제외 키워드 발견 - 알림 스킵
                Debug("수동 참여 제외 키워드 발견 - 텔레그램 알림 스킵")
                RandomDelay(1)
                return -1
            }

            ; 5. 수동 참여 링크를 파일에 저장 (중복 체크 포함)
            SaveManualParticipationLink(copiedLink)

            ; 6. 텔레그램에 링크 전송 (활성화된 경우에만)
            if (g_TelegramManualParticipationNotificationEnabled())
            {
                TelegramSend("⚠️ 수동 참여 필요!" . "`n" . copiedLink)
                GuiControl,, Progress, 텔레그램 알림 전송 완료!
                Debug("텔레그램 알림 전송 완료")
            }
            else
            {
                GuiControl,, Progress, 수동 참여 필요 (텔레그램 알림 비활성화됨)
                Debug("수동 참여 필요 - 텔레그램 알림 비활성화 상태")
            }
            RandomDelay(1)

            ; 텔레그램 전송 후 재시도
            return -1
        }
        else
        {
            ; 9-4. 바로 참여 불가 + 수동 참여 없음 → 스킵
            Debug("바로 참여 불가 + 수동 참여 없음 - 스킵")
            Send, ^w
            return -1
        }
    }

    ; 10. 바로 참여 가능한 경우 여기서 계속 진행
    Debug("댓글 달기 프로세스 시작")
    GuiControl,, Progress, 참여 가능! 추가 정보 수집 중...

    ; Ctrl+W로 탭 닫기
    Send, ^w
    SleepTime(0.5)
    RandomDelay(0.5)

    ; 11. 크롬창에서 전체 선택 및 복사
    Debug("Ctrl+A로 전체 선택")
    Send, ^a
    SleepTime(0.5)
    RandomDelay(0.5)

    Debug("Ctrl+C로 복사")
    Send, ^c
    SleepTime(0.5)
    RandomDelay(0.5)

    ; 12. 클립보드 내용 확인
    ClipWait, 2
    if ErrorLevel
    {
        Debug("클립보드 복사 실패")
        return false
    }

    fullContent := Clipboard
    Debug("전체 복사 내용 길이: " . StrLen(fullContent))

    ; 13. "좋아요 " 이후 부분만 추출
    searchText := "좋아요 "
    foundPos := InStr(fullContent, searchText)

    if (foundPos = 0)
    {
        Debug("전체 복사 내용 : " . fullContent)
        Debug("'좋아요 ' 텍스트를 찾을 수 없습니다")
        return false
    }

    afterPos := foundPos + StrLen(searchText)
    filteredContent := SubStr(fullContent, afterPos)

    ; ===== 바로 참여 제외 키워드 검증 =====
    GuiControl,, Progress, 바로 참여 제외 키워드 검증 중...
    Debug("바로 참여 제외 키워드 검증 시작")

    ; 바로 참여 제외 키워드 체크 (제외 키워드가 있으면 스킵)
    if (CheckDirectParticipationBlacklist(filteredContent))
    {
        retryDelay := g_RetryDelaySeconds()
        Debug("바로 참여 제외 키워드 발견 - 게시물 스킵")
        SleepWithCountdown(retryDelay, "바로 참여 제외 키워드 발견")
        return -1
    }

    GuiControl,, Progress, 검증 통과! 댓글 생성 시작...
    Debug("바로 참여 제외 키워드 검증 통과")

    ; 파일에서 댓글 생성 프롬프트 읽기
    additionalRequest := LoadPromptFromFile("data\AI댓글생성_프롬프트.txt")

    ; 파일을 읽지 못한 경우 빈 문자열
    if (additionalRequest = "")
    {
        Debug("댓글 생성 프롬프트 파일 로드 실패 - 빈 문자열 사용")
    }

    ; 필터링된 내용 + 추가 요청
    Clipboard := filteredContent . "`n`n" . additionalRequest
    Debug("필터링된 내용 길이: " . StrLen(filteredContent))

    ; 14. Ctrl+T로 새 탭 열기 (두 번째 AI 질문)
    Debug("Ctrl+T로 새 탭 열기 (댓글 생성)")
    Send, ^t
    RandomDelay(1.5)

    ; 15. "WRTN 실행 버튼" 이미지 찾아서 클릭 (두 번째)
    GuiControl,, Progress, 두 번째 WRTN AI 실행 버튼 찾는 중...
    Debug("WRTN AI 실행 버튼 이미지 검색 시작 (댓글 생성)")
    wrtnButtonResult2 := ClickAtCenterWhileFoundImage("WRTN 실행 버튼", 5, 1)

    if (!wrtnButtonResult2)
    {
        Debug("WRTN 실행 버튼을 찾을 수 없습니다 (댓글 생성)")
        Send, ^w  ; 탭 닫기
        return 0
    }

    Debug("WRTN 실행 버튼 클릭 성공 (댓글 생성)")
    RandomDelay(3)  ; 페이지 로딩 대기

    ; 15. "무엇이든 물어보세요" 입력창 클릭 (두 번째)
    GuiControl,, Progress, WRTN 입력창 찾는 중...
    Debug("WRTN 입력창 이미지 검색 시작 (댓글 생성)")
    inputBoxResult2 := ClickAtCenterWhileFoundImage("WRTN 입력창", 5, 1)

    if (!inputBoxResult2)
    {
        Debug("WRTN 입력창을 찾을 수 없습니다 (댓글 생성)")
        Send, ^w  ; 탭 닫기
        return 0
    }

    Debug("WRTN 입력창 클릭 성공 (댓글 생성)")
    RandomDelay(0.5)

    ; 17. Ctrl+V로 붙여넣기
    Debug("Ctrl+V로 붙여넣기")
    Send, ^v
    RandomDelay(1)

    ; 18. Enter 키 입력
    Debug("Enter 키 입력")
    Send, {Enter}

    ; 19. 2초 대기 후 클릭 + End
    RandomDelay(2)
    Debug("마우스 클릭")
    Click
    RandomDelay(0.5)
    Debug("End 키로 스크롤 맨 아래로 이동")
    Send, {End}
    RandomDelay(1)

    ; 20. AI 댓글 생성 대기 (최대 10초, 2초마다 복사 버튼 체크)
    GuiControl,, Progress, WRTN AI 댓글 생성 대기 중...
    Debug("WRTN AI 댓글 생성 대기 시작 - 2초마다 체크")

    found := false
    imagePath := A_ScriptDir . "\Image\AI 만들어준 댓글 복사 버튼 WRTN.png"

    Loop, 5
    {
        RandomDelay(2)

        ; 이미지 찾기 (클릭하지 않음)
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath%

        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("WRTN AI 댓글 복사 버튼 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }
    }

    if (!found)
    {
        Debug("최대 대기 시간(10초) 경과 - 복사 버튼 최종 검색")
    }

    ; 21. "AI 만들어준 댓글 복사 버튼 WRTN" 이미지 찾아서 클릭
    GuiControl,, Progress, WRTN AI 댓글 복사 버튼 찾는 중...
    Debug("WRTN AI 만들어준 댓글 복사 버튼 이미지 검색 시작")
    commentCopyResult := ClickAtCenterWhileFoundImage("AI 만들어준 댓글 복사 버튼 WRTN", 5, 2)

    if (!commentCopyResult)
    {
        Debug("WRTN AI 만들어준 댓글 복사 버튼을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return 0
    }

    Debug("WRTN AI 만들어준 댓글 복사 버튼 클릭 성공")
    RandomDelay(0.5)

    ; 20. Ctrl+W로 탭 닫기
    Debug("Ctrl+W로 탭 닫기")
    Send, ^w
    RandomDelay(2)

    ; 21. "비어있는 좋아요 버튼" 찾아서 클릭
    ; 좋아요 전 랜덤 마우스 이동
    RandomMouseMove()

    GuiControl,, Progress, 좋아요 버튼 클릭 중...
    Debug("비어있는 좋아요 버튼 이미지 검색 시작")
    likeButtonResult := ClickAtCenterWhileFoundImage("비어있는 좋아요 버튼", 5, 1)

    if (!likeButtonResult)
    {
        Debug("비어있는 좋아요 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("비어있는 좋아요 버튼 클릭 성공")

    ; 랜덤 딜레이 (기준: 1초)
    RandomDelay(1)

    ; 22. "팔로우 버튼" 있는지 확인하고 있으면 클릭
    GuiControl,, Progress, 팔로우 버튼1 찾는 중...
    Debug("팔로우 버튼1 이미지 검색 시작")
    followResult := ClickAtCenterWhileFoundImage("팔로우 버튼1", 3, 1)

    if (!followResult)
    {
        ; 팔로우 버튼1을 못 찾았으면 팔로우 버튼2 찾기
        Debug("팔로우 버튼1을 찾지 못했습니다. 팔로우 버튼2 검색 시작")
        followResult := ClickAtCenterWhileFoundImage("팔로우 버튼2", 3, 1)
    }

    ; 팔로우 버튼 클릭 결과를 전역 변수에 저장
    g_AlreadyFollowed := followResult

    if (followResult)
    {
        GuiControl,, Progress, 팔로우 버튼 클릭 성공!
        Debug("팔로우 버튼 클릭 성공 - 팔로우 완료")

        ; 랜덤 딜레이 (기준: 0.5초)
        RandomDelay(0.5)
    }
    else
    {
        Debug("팔로우 버튼 없음 - 이미 팔로우된 상태")
    }

    ; 23. "댓글 달기" 버튼 찾아서 클릭
    GuiControl,, Progress, 댓글 달기 버튼 클릭 중...
    Debug("댓글 달기 버튼 이미지 검색 시작")
    commentBoxResult := ClickAtCenterWhileFoundImage("댓글 달기", 5, 1)

    if (!commentBoxResult)
    {
        Debug("댓글 달기 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("댓글 달기 버튼 클릭 성공")

    ; 랜덤 딜레이 (기준: 1초)
    RandomDelay(1)

    ; 24. 댓글 내용 검증 (클립보드에 이상한 내용이 있는지 확인)
    GuiControl,, Progress, 댓글 내용 검증 중...
    commentContent := Clipboard

    ; 출처 링크 완전히 제거: [1](https://...) -> 삭제
    commentContent := RegExReplace(commentContent, "\[(\d+)\]\(https?://[^\)]+\)", "")

    ; 끝부분의 빈 줄 제거
    commentContent := RTrim(commentContent, " `t`r`n")

    ; 수정된 내용을 클립보드에 다시 저장
    Clipboard := commentContent

    Debug("댓글 내용 길이: " . StrLen(commentContent))

    ; "사람처럼", "사람이" 같은 단어가 있으면 AI가 제대로 만들지 못한 것
    if (InStr(commentContent, "사람처럼") > 0 || InStr(commentContent, "사람이") > 0)
    {
        GuiControl,, Progress, AI가 댓글을 제대로 생성하지 못했습니다. 재시도...
        Debug("댓글 내용에 '사람처럼' 또는 '사람이' 발견 - AI 생성 실패로 판단")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; HTTP, HTTPS, URL이 포함되어 있는지 확인
    if (InStr(commentContent, "http://") > 0 || InStr(commentContent, "https://") > 0 || InStr(commentContent, "http") > 0)
    {
        GuiControl,, Progress, 댓글에 URL이 포함되어 있습니다. 재시도...
        Debug("댓글 내용에 HTTP/URL 발견 - 이상한 답변으로 판단")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; 줄 수 확인 (15줄 이상이면 너무 길다)
    lineCount := 0
    Loop, Parse, commentContent, `n
    {
        lineCount++
    }
    Debug("댓글 줄 수: " . lineCount)

    if (lineCount >= 15)
    {
        GuiControl,, Progress, 댓글이 너무 깁니다 (15줄 이상). 재시도...
        Debug("댓글이 너무 김 - " . lineCount . "줄 발견")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; 25. Ctrl+V로 댓글 붙여넣기
    GuiControl,, Progress, 댓글 붙여넣기 중...
    Debug("Ctrl+V로 댓글 붙여넣기")
    Send, ^v

    ; 댓글 길이에 따른 확인 시간 계산
    commentLength := StrLen(commentContent)
    Debug("댓글 길이: " . commentLength . "자")

    ; 기본 확인 시간: 7초 + (글자수 / 30) 초
    ; 예: 30자 = 8초, 60자 = 9초, 90자 = 10초, 120자 = 11초
    baseReviewTime := 7 + (commentLength / 30)

    ; 최소 7초, 최대 13초로 제한
    if (baseReviewTime < 7)
        baseReviewTime := 7
    if (baseReviewTime > 13)
        baseReviewTime := 13

    GuiControl,, Progress, 댓글 내용 확인 중... (%commentLength%자)
    Debug("댓글 확인 시간: " . baseReviewTime . "초 (기준)")
    RandomDelay(baseReviewTime)

    ; 가끔 댓글을 다시 읽는 척 (30% 확률)
    Random, reviewChance, 1, 100
    if (reviewChance <= 30)
    {
        Debug("댓글 내용 재확인 중...")
        RandomDelay(2)
    }

    ; 26. "게시 버튼" 찾아서 클릭
    GuiControl,, Progress, 게시 버튼 클릭 중...
    Debug("게시 버튼 이미지 검색 시작")
    postButtonResult := ClickAtCenterWhileFoundImage("게시 버튼", 5, 1)

    if (!postButtonResult)
    {
        Debug("게시 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("게시 버튼 클릭 성공")

    ; 댓글 카운트 증가
    newCount := IncrementCommentCount()
    limit := GetWarmupTodayLimit()

    if (IsWarmupActive())
    {
        warmupDay := GetWarmupDay()
        percent := GetWarmupDayPercent(warmupDay)
        GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %newCount%/%limit%개, %percent%`%)

        ; 텔레그램 알림
        TelegramSend("✅ 댓글 작성 완료!" . "`n" . "워밍업 D+" . warmupDay . " (" . percent . "%)" . "`n" . "오늘: " . newCount . "/" . limit . "개")
    }
    else
    {
        GuiControl,, CommentCount, 오늘 댓글: %newCount%/%limit%개

        ; 텔레그램 알림
        TelegramSend("✅ 댓글 작성 완료!" . "`n" . "오늘: " . newCount . "/" . limit . "개")
    }
    GuiControl,, Progress, 댓글 작성 완료!

    ; 랜덤 딜레이 (기준: 3초)
    RandomDelay(3)

    Debug("WRTN AI - 두 번째 질문 및 댓글 작성 완료")

    ; 1을 반환하여 성공을 알림
    return 1
}

; AI에게 질문하고 답변 받기 - Perplexity AI 버전
AskAIAndGetResponse_Perplexity()
{
    global g_AlreadyFollowed

    ; 1. Ctrl+T로 새 탭 열기
    Debug("Ctrl+T로 새 탭 열기")
    Send, ^t
    RandomDelay(1.5)

    ; 2. "Perplexity 실행 버튼" 이미지 찾아서 클릭
    GuiControl,, Progress, Perplexity AI 실행 버튼 찾는 중...
    Debug("Perplexity AI 실행 버튼 이미지 검색 시작")
    perplexityButtonResult := ClickAtCenterWhileFoundImage("Perplexity 실행 버튼", 5, 1)

    if (!perplexityButtonResult)
    {
        Debug("Perplexity 실행 버튼을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return false
    }

    Debug("Perplexity 실행 버튼 클릭 성공")
    RandomDelay(3)  ; 페이지 로딩 대기

    ; 2. Ctrl+V로 붙여넣기
    GuiControl,, Progress, 내용 붙여넣기 중...
    Debug("Ctrl+V로 붙여넣기")
    Send, ^v
    RandomDelay(1)

    ; 4. Enter 키 입력
    Debug("Enter 키 입력")
    Send, {Enter}

    ; 5. 마우스를 화면 아래로 이동 (질문 복사 버튼 방지)
    MouseMove, A_ScreenWidth / 2, A_ScreenHeight - 100
    Debug("마우스를 화면 아래로 이동")
    RandomDelay(0.5)

    ; 6. AI 답변 대기 (최대 14초, 2초마다 복사 버튼 체크)
    GuiControl,, Progress, Perplexity AI 답변 대기 중...
    Debug("Perplexity AI 답변 대기 시작 - 2초마다 체크")

    found := false
    imagePath := A_ScriptDir . "\Image\AI 답변 내용 복사 버튼 Perplexity.png"

    Loop, 7
    {
        RandomDelay(2)

        ; 이미지 찾기 (클릭하지 않음)
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath%

        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("Perplexity AI 답변 복사 버튼 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }
    }

    if (!found)
    {
        Debug("최대 대기 시간(14초) 경과 - 복사 버튼 최종 검색")
    }

    ; 7. "AI 답변 내용 복사 버튼 Perplexity" 이미지 찾아서 클릭
    GuiControl,, Progress, Perplexity AI 답변 복사 버튼 찾는 중...
    Debug("Perplexity AI 답변 내용 복사 버튼 이미지 검색 시작")
    copyButtonResult := ClickAtCenterWhileFoundImage("AI 답변 내용 복사 버튼 Perplexity", 10, 2)

    if (!copyButtonResult)
    {
        Debug("Perplexity AI 답변 내용 복사 버튼을 찾을 수 없습니다")
        Send, ^w  ; 탭 닫기
        return false
    }

    Debug("Perplexity AI 답변 내용 복사 버튼 클릭 성공")
    RandomDelay(1)

    ; 6. 클립보드 내용 확인 (AI 답변)
    ClipWait, 2
    if ErrorLevel
    {
        Debug("클립보드 복사 실패")
        Send, ^w  ; 탭 닫기
        return false
    }

    aiResponse := Clipboard

    ; 출처 링크 완전히 제거: [1](https://...) -> 삭제
    aiResponse := RegExReplace(aiResponse, "\[(\d+)\]\(https?://[^\)]+\)", "")

    ; 끝부분의 빈 줄 제거
    aiResponse := RTrim(aiResponse, " `t`r`n")

    Debug("Perplexity AI 답변 길이: " . StrLen(aiResponse))

    ; 7. AI 답변 분석
    global g_LastFilteredContent, g_TestMode

    ; 테스트 모드일 때는 AI 답변 분석 스킵하고 무조건 바로 참여 가능으로 처리
    if (g_TestMode)
    {
        Debug("[테스트 모드] AI 답변 분석 스킵 - 무조건 바로 참여 가능으로 처리")
        isExcluded := false
        isDirectParticipation := true
        isOngoing := true
        isFormRequired := false
    }
    else
    {
        isExcluded := (InStr(aiResponse, "제외 판단 - 예") > 0 || InStr(aiResponse, "제외 판단-예") > 0)
        isDirectParticipation := (InStr(aiResponse, "바로 참여 여부 - 가능") > 0 || InStr(aiResponse, "바로 참여 여부-가능") > 0)
        isOngoing := (InStr(aiResponse, "진행중") > 0)

        ; 수동 참여 필요 여부는 게시물 내용에서 키워드 매칭으로 판단
        isFormRequired := CheckManualParticipationKeywords(g_LastFilteredContent)
    }

    ; 7-1. 제외 판단이 예이면 스킵
    if (isExcluded)
    {
        Debug("제외 판단 - 스킵")
        Send, ^w
        return -1
    }

    ; 7-2. 바로 참여 가능하면 댓글 달기 진행
    if (isDirectParticipation)
    {
        Debug("바로 참여 가능 - 댓글 달기 진행")
        ; 아래에서 계속 진행됨
    }
    else
    {
        ; 7-3. 바로 참여 불가 + 수동 참여 필요 + 진행중 → 텔레그램 전송
        if (isFormRequired && isOngoing)
        {
            ; 수동 참여 알림이 비활성화되어 있으면 건너뛰기
            global MANUAL_PARTICIPATION_ALERT_ENABLED
            if (MANUAL_PARTICIPATION_ALERT_ENABLED = "false" || MANUAL_PARTICIPATION_ALERT_ENABLED = "0")
            {
                Debug("수동 참여 알림 비활성화 상태 - 스킵")
                Send, ^w
                return -1
            }

            Debug("바로 참여 불가 + 수동 참여 필요 이벤트 발견 - 텔레그램 알림 시작")

            ; AI 탭을 먼저 닫아서 인스타그램 화면이 보이도록 함
            Send, ^w
            RandomDelay(0.5)
            Debug("Perplexity AI 탭 닫기 완료 - 인스타그램 화면으로 전환")

            ; 1. "인스타그램 팝업 메뉴 버튼" 클릭
            GuiControl,, Progress, 인스타그램 팝업 메뉴 버튼 클릭 중...
            popupMenuResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 메뉴 버튼", 5, 1)

            if (!popupMenuResult)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("인스타그램 팝업 메뉴 버튼을 찾을 수 없습니다. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "인스타그램 팝업 메뉴 버튼을 찾을 수 없습니다")
                return -1
            }

            Debug("인스타그램 팝업 메뉴 버튼 클릭 성공")
            RandomDelay(2)

            ; 2. "인스타그램 팝업 링크복사 버튼" 클릭
            GuiControl,, Progress, 링크 복사 버튼 클릭 중...
            linkCopyResult := ClickAtCenterWhileFoundImage("인스타그램 팝업 링크복사 버튼", 5, 1)

            if (!linkCopyResult)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("인스타그램 팝업 링크복사 버튼을 찾을 수 없습니다. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "인스타그램 팝업 링크복사 버튼을 찾을 수 없습니다")
                return -1
            }

            Debug("인스타그램 팝업 링크복사 버튼 클릭 성공")
            RandomDelay(1)

            ; 3. 클립보드에서 링크 가져오기
            ClipWait, 2
            if (ErrorLevel)
            {
                retryDelay := g_RetryDelaySeconds()
                Debug("링크 복사 실패. " . retryDelay . "초 후 재시도")
                SleepWithCountdown(retryDelay, "링크 복사 실패")
                return -1
            }

            copiedLink := Clipboard
            Debug("링크 복사 완료: " . copiedLink)

            ; 4. 수동 참여 제외 키워드 체크
            global g_LastFilteredContent
            if (CheckManualParticipationBlacklist(g_LastFilteredContent))
            {
                GuiControl,, Progress, 수동 참여 제외 키워드 발견 - 알림 스킵
                Debug("수동 참여 제외 키워드 발견 - 텔레그램 알림 스킵")
                RandomDelay(1)
                return -1
            }

            ; 5. 수동 참여 링크를 파일에 저장 (중복 체크 포함)
            SaveManualParticipationLink(copiedLink)

            ; 6. 텔레그램에 링크 전송 (활성화된 경우에만)
            if (g_TelegramManualParticipationNotificationEnabled())
            {
                TelegramSend("⚠️ 수동 참여 필요!" . "`n" . copiedLink)
                GuiControl,, Progress, 텔레그램 알림 전송 완료!
                Debug("텔레그램 알림 전송 완료")
            }
            else
            {
                GuiControl,, Progress, 수동 참여 필요 (텔레그램 알림 비활성화됨)
                Debug("수동 참여 필요 - 텔레그램 알림 비활성화 상태")
            }
            RandomDelay(1)

            ; 텔레그램 전송 후 재시도
            return -1
        }
        else
        {
            ; 7-4. 바로 참여 불가 + 수동 참여 없음 → 스킵
            Debug("바로 참여 불가 + 수동 참여 없음 - 스킵")
            Send, ^w
            return -1
        }
    }

    ; 8. 바로 참여 가능한 경우 여기서 계속 진행
    Debug("댓글 달기 프로세스 시작")
    GuiControl,, Progress, 참여 가능! 추가 정보 수집 중...

    ; Ctrl+W로 탭 닫기
    Send, ^w
    SleepTime(0.5)
    RandomDelay(0.5)

    ; 9. 크롬창에서 전체 선택 및 복사
    Debug("Ctrl+A로 전체 선택")
    Send, ^a
    SleepTime(0.5)
    RandomDelay(0.5)

    Debug("Ctrl+C로 복사")
    Send, ^c
    SleepTime(0.5)
    RandomDelay(0.5)

    ; 10. 클립보드 내용 확인
    ClipWait, 2
    if ErrorLevel
    {
        Debug("클립보드 복사 실패")
        return false
    }

    fullContent := Clipboard
    Debug("전체 복사 내용 길이: " . StrLen(fullContent))

    ; 11. "좋아요 " 이후 부분만 추출
    searchText := "좋아요 "
    foundPos := InStr(fullContent, searchText)

    if (foundPos = 0)
    {
        Debug("전체 복사 내용 : " . fullContent)
        Debug("'좋아요 ' 텍스트를 찾을 수 없습니다")
        return false
    }

    afterPos := foundPos + StrLen(searchText)
    filteredContent := SubStr(fullContent, afterPos)

    ; ===== 바로 참여 제외 키워드 검증 =====
    GuiControl,, Progress, 바로 참여 제외 키워드 검증 중...
    Debug("바로 참여 제외 키워드 검증 시작")

    ; 바로 참여 제외 키워드 체크 (제외 키워드가 있으면 스킵)
    if (CheckDirectParticipationBlacklist(filteredContent))
    {
        retryDelay := g_RetryDelaySeconds()
        Debug("바로 참여 제외 키워드 발견 - 게시물 스킵")
        SleepWithCountdown(retryDelay, "바로 참여 제외 키워드 발견")
        return -1
    }

    GuiControl,, Progress, 검증 통과! 댓글 생성 시작...
    Debug("바로 참여 제외 키워드 검증 통과")

    ; 파일에서 댓글 생성 프롬프트 읽기
    additionalRequest := LoadPromptFromFile("data\AI댓글생성_프롬프트.txt")

    ; 파일을 읽지 못한 경우 빈 문자열
    if (additionalRequest = "")
    {
        Debug("댓글 생성 프롬프트 파일 로드 실패 - 빈 문자열 사용")
    }

    ; 필터링된 내용 + 추가 요청
    Clipboard := filteredContent . "`n`n" . additionalRequest
    Debug("필터링된 내용 길이: " . StrLen(filteredContent))

    ; 12. Ctrl+T로 새 탭 열기 (두 번째 AI 질문)
    Debug("Ctrl+T로 새 탭 열기 (댓글 생성)")
    Send, ^t
    RandomDelay(1.5)

    ; 13. "Perplexity 실행 버튼" 이미지 찾아서 클릭 (두 번째)
    GuiControl,, Progress, 두 번째 Perplexity AI 실행 버튼 찾는 중...
    Debug("Perplexity AI 실행 버튼 이미지 검색 시작 (댓글 생성)")
    perplexityButtonResult2 := ClickAtCenterWhileFoundImage("Perplexity 실행 버튼", 5, 1)

    if (!perplexityButtonResult2)
    {
        Debug("Perplexity 실행 버튼을 찾을 수 없습니다 (댓글 생성)")
        Send, ^w  ; 탭 닫기
        return 0
    }

    Debug("Perplexity 실행 버튼 클릭 성공 (댓글 생성)")
    RandomDelay(3)  ; 페이지 로딩 대기

    ; 13. Ctrl+V로 붙여넣기
    Debug("Ctrl+V로 붙여넣기")
    Send, ^v
    RandomDelay(1)

    ; 15. Enter 키 입력
    Debug("Enter 키 입력")
    Send, {Enter}

    ; 16. 마우스를 화면 아래로 이동 (질문 복사 버튼 방지)
    MouseMove, A_ScreenWidth / 2, A_ScreenHeight - 100
    Debug("마우스를 화면 아래로 이동")
    RandomDelay(0.5)

    ; 17. AI 댓글 생성 대기 (최대 12초, 2초마다 복사 버튼 체크)
    GuiControl,, Progress, Perplexity AI 댓글 생성 대기 중...
    Debug("Perplexity AI 댓글 생성 대기 시작 - 2초마다 체크")

    found := false
    imagePath1 := A_ScriptDir . "\Image\AI 만들어준 댓글 복사 버튼 Perplexity1.png"
    imagePath2 := A_ScriptDir . "\Image\AI 만들어준 댓글 복사 버튼 Perplexity2.png"
    imagePath3 := A_ScriptDir . "\Image\AI 만들어준 댓글 복사 버튼 Perplexity3.png"

    Loop, 6
    {
        RandomDelay(2)

        ; 이미지 찾기 (3개 중 하나라도 찾으면 종료)
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath1%
        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("Perplexity AI 댓글 복사 버튼1 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }

        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath2%
        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("Perplexity AI 댓글 복사 버튼2 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }

        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %imagePath3%
        if (!ErrorLevel)
        {
            waitTime := A_Index * 2
            Debug("Perplexity AI 댓글 복사 버튼3 발견 - " . waitTime . "초만에 답변 완료")
            found := true
            break
        }
    }

    if (!found)
    {
        Debug("최대 대기 시간(12초) 경과 - 복사 버튼 최종 검색")
    }

    ; 18. "AI 만들어준 댓글 복사 버튼 Perplexity" 이미지 찾아서 클릭 (1, 2, 3 순서로)
    GuiControl,, Progress, Perplexity AI 댓글 복사 버튼1 찾는 중...
    Debug("Perplexity AI 만들어준 댓글 복사 버튼1 이미지 검색 시작")
    commentCopyResult := ClickAtCenterWhileFoundImage("AI 만들어준 댓글 복사 버튼 Perplexity1", 3, 2)

    if (!commentCopyResult)
    {
        ; 첫 번째 버튼을 못 찾았으면 두 번째 버튼 찾기
        GuiControl,, Progress, Perplexity AI 댓글 복사 버튼2 찾는 중...
        Debug("Perplexity AI 만들어준 댓글 복사 버튼1을 찾지 못했습니다. 버튼2 검색 시작")
        commentCopyResult := ClickAtCenterWhileFoundImage("AI 만들어준 댓글 복사 버튼 Perplexity2", 3, 2)

        if (!commentCopyResult)
        {
            ; 두 번째 버튼도 못 찾았으면 세 번째 버튼 찾기
            GuiControl,, Progress, Perplexity AI 댓글 복사 버튼3 찾는 중...
            Debug("Perplexity AI 만들어준 댓글 복사 버튼2도 찾지 못했습니다. 버튼3 검색 시작")
            commentCopyResult := ClickAtCenterWhileFoundImage("AI 만들어준 댓글 복사 버튼 Perplexity3", 3, 2)

            if (!commentCopyResult)
            {
                Debug("Perplexity AI 만들어준 댓글 복사 버튼1, 2, 3 모두 찾을 수 없습니다")
                Send, ^w  ; 탭 닫기
                return 0
            }
        }
    }

    Debug("Perplexity AI 만들어준 댓글 복사 버튼 클릭 성공")
    RandomDelay(0.5)

    ; 17. Ctrl+W로 탭 닫기
    Debug("Ctrl+W로 탭 닫기")
    Send, ^w
    RandomDelay(2)

    ; 18. "비어있는 좋아요 버튼" 찾아서 클릭
    ; 좋아요 전 랜덤 마우스 이동
    RandomMouseMove()

    GuiControl,, Progress, 좋아요 버튼 클릭 중...
    Debug("비어있는 좋아요 버튼 이미지 검색 시작")
    likeButtonResult := ClickAtCenterWhileFoundImage("비어있는 좋아요 버튼", 5, 1)

    if (!likeButtonResult)
    {
        Debug("비어있는 좋아요 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("비어있는 좋아요 버튼 클릭 성공")

    ; 랜덤 딜레이 (기준: 1초)
    RandomDelay(1)

    ; 19. "팔로우 버튼" 있는지 확인하고 있으면 클릭
    GuiControl,, Progress, 팔로우 버튼1 찾는 중...
    Debug("팔로우 버튼1 이미지 검색 시작")
    followResult := ClickAtCenterWhileFoundImage("팔로우 버튼1", 3, 1)

    if (!followResult)
    {
        ; 팔로우 버튼1을 못 찾았으면 팔로우 버튼2 찾기
        Debug("팔로우 버튼1을 찾지 못했습니다. 팔로우 버튼2 검색 시작")
        followResult := ClickAtCenterWhileFoundImage("팔로우 버튼2", 3, 1)
    }

    ; 팔로우 버튼 클릭 결과를 전역 변수에 저장
    g_AlreadyFollowed := followResult

    if (followResult)
    {
        GuiControl,, Progress, 팔로우 버튼 클릭 성공!
        Debug("팔로우 버튼 클릭 성공 - 팔로우 완료")

        ; 랜덤 딜레이 (기준: 0.5초)
        RandomDelay(0.5)
    }
    else
    {
        Debug("팔로우 버튼 없음 - 이미 팔로우된 상태")
    }

    ; 20. "댓글 달기" 버튼 찾아서 클릭
    GuiControl,, Progress, 댓글 달기 버튼 클릭 중...
    Debug("댓글 달기 버튼 이미지 검색 시작")
    commentBoxResult := ClickAtCenterWhileFoundImage("댓글 달기", 5, 1)

    if (!commentBoxResult)
    {
        Debug("댓글 달기 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("댓글 달기 버튼 클릭 성공")

    ; 랜덤 딜레이 (기준: 1초)
    RandomDelay(1)

    ; 21. 댓글 내용 검증 (클립보드에 이상한 내용이 있는지 확인)
    GuiControl,, Progress, 댓글 내용 검증 중...
    commentContent := Clipboard

    ; 출처 링크 완전히 제거: [1](https://...) -> 삭제
    commentContent := RegExReplace(commentContent, "\[(\d+)\]\(https?://[^\)]+\)", "")

    ; 끝부분의 빈 줄 제거
    commentContent := RTrim(commentContent, " `t`r`n")

    ; 수정된 내용을 클립보드에 다시 저장
    Clipboard := commentContent

    Debug("댓글 내용 길이: " . StrLen(commentContent))

    ; "사람처럼", "사람이" 같은 단어가 있으면 AI가 제대로 만들지 못한 것
    if (InStr(commentContent, "사람처럼") > 0 || InStr(commentContent, "사람이") > 0)
    {
        GuiControl,, Progress, AI가 댓글을 제대로 생성하지 못했습니다. 재시도...
        Debug("댓글 내용에 '사람처럼' 또는 '사람이' 발견 - AI 생성 실패로 판단")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; HTTP, HTTPS, URL이 포함되어 있는지 확인
    if (InStr(commentContent, "http://") > 0 || InStr(commentContent, "https://") > 0 || InStr(commentContent, "http") > 0)
    {
        GuiControl,, Progress, 댓글에 URL이 포함되어 있습니다. 재시도...
        Debug("댓글 내용에 HTTP/URL 발견 - 이상한 답변으로 판단")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; 줄 수 확인 (15줄 이상이면 너무 길다)
    lineCount := 0
    Loop, Parse, commentContent, `n
    {
        lineCount++
    }
    Debug("댓글 줄 수: " . lineCount)

    if (lineCount >= 15)
    {
        GuiControl,, Progress, 댓글이 너무 깁니다 (15줄 이상). 재시도...
        Debug("댓글이 너무 김 - " . lineCount . "줄 발견")

        ; ESC로 댓글 입력창 닫기
        Send, {Esc}
        RandomDelay(1)

        ; -1을 반환하여 재시도하도록 함
        return -1
    }

    ; 22. Ctrl+V로 댓글 붙여넣기
    GuiControl,, Progress, 댓글 붙여넣기 중...
    Debug("Ctrl+V로 댓글 붙여넣기")
    Send, ^v

    ; 댓글 길이에 따른 확인 시간 계산
    commentLength := StrLen(commentContent)
    Debug("댓글 길이: " . commentLength . "자")

    ; 기본 확인 시간: 7초 + (글자수 / 30) 초
    ; 예: 30자 = 8초, 60자 = 9초, 90자 = 10초, 120자 = 11초
    baseReviewTime := 7 + (commentLength / 30)

    ; 최소 7초, 최대 13초로 제한
    if (baseReviewTime < 7)
        baseReviewTime := 7
    if (baseReviewTime > 13)
        baseReviewTime := 13

    GuiControl,, Progress, 댓글 내용 확인 중... (%commentLength%자)
    Debug("댓글 확인 시간: " . baseReviewTime . "초 (기준)")
    RandomDelay(baseReviewTime)

    ; 가끔 댓글을 다시 읽는 척 (30% 확률)
    Random, reviewChance, 1, 100
    if (reviewChance <= 30)
    {
        Debug("댓글 내용 재확인 중...")
        RandomDelay(2)
    }

    ; 22. "게시 버튼" 찾아서 클릭
    GuiControl,, Progress, 게시 버튼 클릭 중...
    Debug("게시 버튼 이미지 검색 시작")
    postButtonResult := ClickAtCenterWhileFoundImage("게시 버튼", 5, 1)

    if (!postButtonResult)
    {
        Debug("게시 버튼을 찾을 수 없습니다")
        return 0
    }

    Debug("게시 버튼 클릭 성공")

    ; 댓글 카운트 증가
    newCount := IncrementCommentCount()
    limit := GetWarmupTodayLimit()

    if (IsWarmupActive())
    {
        warmupDay := GetWarmupDay()
        percent := GetWarmupDayPercent(warmupDay)
        GuiControl,, CommentCount, 워밍업 D+%warmupDay% (오늘: %newCount%/%limit%개, %percent%`%)

        ; 텔레그램 알림
        TelegramSend("✅ 댓글 작성 완료!" . "`n" . "워밍업 D+" . warmupDay . " (" . percent . "%)" . "`n" . "오늘: " . newCount . "/" . limit . "개")
    }
    else
    {
        GuiControl,, CommentCount, 오늘 댓글: %newCount%/%limit%개

        ; 텔레그램 알림
        TelegramSend("✅ 댓글 작성 완료!" . "`n" . "오늘: " . newCount . "/" . limit . "개")
    }
    GuiControl,, Progress, 댓글 작성 완료!

    ; 랜덤 딜레이 (기준: 3초)
    RandomDelay(3)

    Debug("Perplexity AI - 두 번째 질문 및 댓글 작성 완료")

    ; 1을 반환하여 성공을 알림
    return 1
}

; AI에게 질문하고 답변 받기 - 환경 변수에 따라 우선순위 결정
AskAIAndGetResponse()
{
    global AI_PRIORITY

    ; 환경 변수에 따라 우선순위 결정 (기본값: PERPLEXITY)
    if (AI_PRIORITY = "WRTN")
    {
        ; WRTN 우선 모드
        Debug("AI 질문 시작 - WRTN AI 우선 시도")

        ; 1. 먼저 WRTN AI 시도
        result := AskAIAndGetResponse_WRTN()

        ; 2. WRTN AI가 성공하면 결과 반환
        if (result != false)
        {
            Debug("WRTN AI 성공")
            return result
        }

        ; 3. WRTN AI 실패 시 Perplexity AI로 자동 전환
        Debug("WRTN AI 실패 - Perplexity AI로 전환 시도")
        GuiControl,, Progress, WRTN AI 실패 - Perplexity AI로 재시도 중...

        ; 4. Perplexity AI 시도
        result := AskAIAndGetResponse_Perplexity()

        if (result != false)
        {
            Debug("Perplexity AI 성공")
            return result
        }

        ; 5. 둘 다 실패
        Debug("WRTN AI와 Perplexity AI 모두 실패")
        return false
    }
    else
    {
        ; Perplexity 우선 모드 (기본값)
        Debug("AI 질문 시작 - Perplexity AI 우선 시도")

        ; 1. 먼저 Perplexity AI 시도
        result := AskAIAndGetResponse_Perplexity()

        ; 2. Perplexity AI가 성공하면 결과 반환
        if (result != false)
        {
            Debug("Perplexity AI 성공")
            return result
        }

        ; 3. Perplexity AI 실패 시 WRTN AI로 자동 전환
        Debug("Perplexity AI 실패 - WRTN AI로 전환 시도")
        GuiControl,, Progress, Perplexity AI 실패 - WRTN AI로 재시도 중...

        ; 4. WRTN AI 시도
        result := AskAIAndGetResponse_WRTN()

        if (result != false)
        {
            Debug("WRTN AI 성공")
            return result
        }

        ; 5. 둘 다 실패
        Debug("Perplexity AI와 WRTN AI 모두 실패")
        return false
    }
}

; ==========================================
; 키워드 검증 함수들
; ==========================================

; 파일에서 프롬프트 텍스트 로드
LoadPromptFromFile(fileName)
{
    filePath := A_ScriptDir . "\" . fileName

    ; 파일 존재 여부 확인
    if (!FileExist(filePath))
    {
        Debug("프롬프트 파일을 찾을 수 없습니다: " . filePath)
        return ""
    }

    ; 파일 읽기
    FileRead, fileContent, %filePath%

    Debug("프롬프트 파일 로드 완료: " . fileName . " (길이: " . StrLen(fileContent) . ")")
    return fileContent
}

; 파일에서 키워드 리스트 로드
LoadKeywordsFromFile(fileName)
{
    keywords := []
    filePath := A_ScriptDir . "\" . fileName

    ; 파일 존재 여부 확인
    if (!FileExist(filePath))
    {
        Debug(fileName . " 파일을 찾을 수 없습니다: " . filePath)
        return keywords
    }

    ; 파일 읽기
    FileRead, fileContent, %filePath%

    ; 줄 단위로 분리
    Loop, Parse, fileContent, `n, `r
    {
        keyword := Trim(A_LoopField)
        if (keyword != "")
        {
            keywords.Push(keyword)
            Debug("키워드 로드: " . keyword)
        }
    }

    Debug(fileName . "에서 " . keywords.Length() . "개 키워드 로드 완료")
    return keywords
}

; 제외 키워드 체크 - 전체 처리 중단용 (하나라도 있으면 true)
CheckBlacklist(text)
{
    global g_TestMode
    if (g_TestMode)
    {
        Debug("[테스트 모드] 제외 키워드 검사 스킵 - 무조건 통과")
        return false
    }

    blacklist := LoadKeywordsFromFile("data\제외키워드.txt")

    for index, keyword in blacklist
    {
        if (InStr(text, keyword) > 0)
        {
            Debug("제외 키워드 발견: " . keyword)
            return true
        }
    }

    Debug("제외 키워드 없음 - 통과")
    return false
}

; 바로 참여 제외 키워드 체크 (하나라도 있으면 true)
CheckDirectParticipationBlacklist(text)
{
    global g_TestMode
    if (g_TestMode)
    {
        Debug("[테스트 모드] 바로 참여 제외 키워드 검사 스킵 - 무조건 통과")
        return false
    }

    blacklist := LoadKeywordsFromFile("data\바로참여제외키워드.txt")

    for index, keyword in blacklist
    {
        if (InStr(text, keyword) > 0)
        {
            Debug("바로 참여 제외 키워드 발견: " . keyword)
            return true
        }
    }

    Debug("바로 참여 제외 키워드 없음 - 통과")
    return false
}

; 수동 참여 제외 키워드 체크 (하나라도 있으면 true)
CheckManualParticipationBlacklist(text)
{
    blacklist := LoadKeywordsFromFile("data\수동참여제외키워드.txt")

    for index, keyword in blacklist
    {
        if (InStr(text, keyword) > 0)
        {
            Debug("수동 참여 제외 키워드 발견: " . keyword)
            return true
        }
    }

    Debug("수동 참여 제외 키워드 없음 - 알림 가능")
    return false
}

; 이벤트 판단 키워드 체크 (하나라도 있으면 true)
CheckEventKeywords(text)
{
    global g_TestMode
    if (g_TestMode)
    {
        Debug("[테스트 모드] 이벤트 키워드 검사 스킵 - 무조건 통과")
        return true
    }

    eventKeywords := LoadKeywordsFromFile("data\이벤트판단키워드.txt")

    for index, keyword in eventKeywords
    {
        if (InStr(text, keyword) > 0)
        {
            Debug("이벤트 판단 키워드 발견: " . keyword)
            return true
        }
    }

    Debug("이벤트 판단 키워드 없음 - 이벤트 아님")
    return false
}

; 수동 참여 키워드 체크 (하나라도 있으면 true)
CheckManualParticipationKeywords(text)
{
    global g_TestMode
    if (g_TestMode)
    {
        Debug("[테스트 모드] 수동 참여 키워드 검사 스킵 - 무조건 자동 참여 가능")
        return false
    }

    manualKeywords := LoadKeywordsFromFile("data\수동참여키워드.txt")

    for index, keyword in manualKeywords
    {
        if (InStr(text, keyword) > 0)
        {
            Debug("수동 참여 키워드 발견: " . keyword)
            return true
        }
    }

    Debug("수동 참여 키워드 없음 - 자동 참여 가능")
    return false
}
