; 파일 인코딩 설정 (한글 깨짐 방지)
FileEncoding, UTF-8

#Include GlobalData.ahk
#Include EnvData.ahk
#include Gdip_All.ahk

; 대기 함수 (초 단위)
SleepTime(second)
{
    Sleep, g_OneSecond() * second
}

; 카운트다운 대기 함수 (초 단위, GUI에 남은 시간 표시)
; seconds: 대기할 초
; message: 표시할 메시지 (남은 시간은 자동으로 추가됨)
SleepWithCountdown(seconds, message := "대기 중")
{
    Loop, %seconds%
    {
        ; 중지 요청 확인
        global isRunning
        if (!isRunning)
        {
            GuiControl,, Progress, 작업이 중지되었습니다.
            return false
        }

        remainingSeconds := seconds - A_Index + 1

        ; 60초 이상이면 분:초로 표시
        if (remainingSeconds >= 60)
        {
            remainingMinutes := Floor(remainingSeconds / 60)
            remainingSecondsOnly := Mod(remainingSeconds, 60)
            timeDisplay := remainingMinutes . "분 " . remainingSecondsOnly . "초"
        }
        else
        {
            timeDisplay := remainingSeconds . "초"
        }

        GuiControl,, Progress, %message%... (남은 시간: %timeDisplay%)
        Sleep, 1000  ; 1초 대기
    }
    return true
}

; 랜덤 딜레이 함수 (초 단위)
; baseTime: 기준 대기 시간 (초 단위)
; 함수 내부에서 baseTime을 기준으로 자동으로 랜덤 범위 계산
RandomDelay(baseTime)
{
    ; 랜덤 딜레이가 비활성화된 경우 기준 시간만큼만 대기
    if (!g_RandomDelayEnabled())
    {
        Debug("랜덤 딜레이 비활성화 - 기준 시간 " . baseTime . "초 대기")
        SleepTime(baseTime)
        return
    }

    ; 변동폭 계산 (기준 시간 * 변동 비율)
    variation := baseTime * g_RandomDelayVariationRatio()

    ; 변동폭이 최소값보다 작으면 최소값 사용
    if (variation < g_RandomDelayMinVariation())
    {
        variation := g_RandomDelayMinVariation()
    }

    ; 변동폭이 최대값보다 크면 최대값 사용
    if (variation > g_RandomDelayMaxVariation())
    {
        variation := g_RandomDelayMaxVariation()
    }

    ; 최소/최대 시간 계산
    minTime := baseTime - variation
    maxTime := baseTime + variation

    ; 최소 시간이 너무 짧지 않게 (최소 0.5초)
    if (minTime < 0.5)
    {
        minTime := 0.5
    }

    ; 랜덤 시간 계산 (정수로 변환)
    Random, randomSeconds, % Floor(minTime), % Floor(maxTime)

    Debug("랜덤 딜레이: " . randomSeconds . "초 대기 (기준: " . baseTime . "초, 범위: " . Floor(minTime) . "~" . Floor(maxTime) . "초)")

    ; 대기 실행
    SleepTime(randomSeconds)
}

; 디버그 출력
Debug(value)
{
    if (g_DebugMode())
    {
        nowTime := GetFormattedCurrentDateTime()
        logMessage := nowTime . " " . value . "`n"
        ; 콘솔 출력
        FileAppend, %logMessage%, *
        ShowPopup(value, 2)
    }
}

; 현재 날짜 및 시간 반환
GetFormattedCurrentDateTime()
{
    FormatTime, 현재날짜시간, , yyyy/MM/dd HH:mm:ss
    return 현재날짜시간
}

; 팝업을 보여주는 함수
ShowPopup(text, duration) {
    ToolTip, %text%, 0, A_ScreenHeight - 10
    durationValue := duration * 1000
    SetTimer, HidePopup, % -durationValue
    return
}

; 팝업을 숨기는 함수
HidePopup() {
    ToolTip
}

; 화면 좌표로 마우스 이동
ScreenMouseMove(x, y)
{
    CoordMode, Mouse, Screen
    mousemove, %x%, %y%
}

; 현재 위치에서 마우스 클릭
NowMouseClick()
{
    CoordMode, Mouse, Screen
    MouseGetPos, currentX, currentY
    MouseClick, Left, %currentX%, %currentY%, 1
}

; 이미지를 화면 전체에서 검색해서 검색 정보를 Byref로 값을 넘김
FindImage_Byref(imageName, Byref errLevel, Byref foundX, Byref foundY, searchStart_x := 0, searchStart_y := 0, searchEnd_x := -1, searchEnd_y := -1)
{
    Debug("이미지 검색 시작: " . imageName)
    CoordMode, Pixel, Screen

    if(searchEnd_x = -1)
    {
        searchEnd_x := A_ScreenWidth
    }
    if(searchEnd_y = -1)
    {
        searchEnd_y := A_ScreenHeight
    }

    ImageSearch, FoundX, FoundY, searchStart_x, searchStart_y, searchEnd_x, searchEnd_y, *Trans091A36 *40 %A_ScriptDir%\Image\%imageName%.png

    Debug(imageName . " - ErrorLevel:" . ErrorLevel . " FoundX:" . FoundX . " FoundY:" . FoundY)
    errLevel := ErrorLevel
    foundX := FoundX
    foundY := FoundY
}

; 이미지 찾을 때까지 대기
WhileFoundImage(imageName, findMaxCount := 10, delayTime := 1, searchStart_x := 0, searchStart_y := 0)
{
    findCount := 0
    while (true)
    {
        FindImage_Byref(imageName, Byref_errlevel, Byref_foundX, Byref_foundY, searchStart_x, searchStart_y)
        if(Byref_errlevel = g_ErrorType_Success() && Byref_foundX != "" && Byref_foundY != "")
        {
            SleepTime(0.5)
            return true
        }
        SleepTime(delayTime)
        ++findCount
        if(findMaxCount <= findCount)
        {
            Debug("Error WhileFoundImage - " . findMaxCount . "번을 찾았으나 실패했습니다. imageName : " . imageName)
            return false
        }
    }
}

; 이미지 찾아서 클릭
ClickAtWhileFoundImage(imageName, addX := 0, addY := 0, findMaxCount := 10, delayTime := 1, searchStart_x := 0, searchStart_y := 0, searchEnd_x := -1, searchEnd_y := -1)
{
    findCount := 0
    while (true)
    {
        FindImage_Byref(imageName, Byref_errlevel, Byref_foundX, Byref_foundY, searchStart_x, searchStart_y, searchEnd_x, searchEnd_y)
        if(Byref_errlevel = g_ErrorType_Success() && Byref_foundX != "" && Byref_foundY != "")
        {
            Byref_foundX += addX
            Byref_foundY += addY
            CoordMode, Mouse, Screen
            mousemove, %Byref_foundX%, %Byref_foundY%
            SleepTime(0.5)
            MouseClick, Left, %Byref_foundX%, %Byref_foundY%, 1
            Debug("이미지 클릭 성공: " . imageName . " at (" . Byref_foundX . ", " . Byref_foundY . ")")
            return true
        }
        SleepTime(delayTime)
        ++findCount
        if(findMaxCount <= findCount)
        {
            Debug("Error ClickAtWhileFoundImage - " . findMaxCount . "번을 찾았으나 실패했습니다. imageName : " . imageName)
            return false
        }
    }
}

; 이미지 찾아서 마우스 이동
MoveAtWhileFoundImage(imageName, addX := 0, addY := 0, findMaxCount := 10, delayTime := 1, searchStart_x := 0, searchStart_y := 0)
{
    findCount := 0
    while (true)
    {
        FindImage_Byref(imageName, Byref_errlevel, Byref_foundX, Byref_foundY, searchStart_x, searchStart_y)
        if(Byref_errlevel = g_ErrorType_Success() && Byref_foundX != "" && Byref_foundY != "")
        {
            Byref_foundX += addX
            Byref_foundY += addY
            CoordMode, Mouse, Screen
            mousemove, %Byref_foundX%, %Byref_foundY%
            SleepTime(0.5)
            Debug("이미지로 이동 성공: " . imageName . " at (" . Byref_foundX . ", " . Byref_foundY . ")")
            return true
        }
        SleepTime(delayTime)
        ++findCount
        if(findMaxCount <= findCount)
        {
            Debug("Error MoveAtWhileFoundImage - " . findMaxCount . "번을 찾았으나 실패했습니다. imageName : " . imageName)
            return false
        }
    }
}

; 이미지 존재 여부 확인
IsImageExist(imageName, searchStart_x := 0, searchStart_y := 0)
{
    CoordMode, Pixel, Screen
    ImageSearch, FoundX, FoundY, searchStart_x, searchStart_y, A_ScreenWidth, A_ScreenHeight, *Trans091A36 *40 %A_ScriptDir%\Image\%imageName%.png
    return (ErrorLevel = g_ErrorType_Success() && FoundX != "" && FoundY != "")
}

; 이미지 크기 가져오기 (GDI+ 사용)
GetImageSize(imageName, Byref width, Byref height)
{
    imagePath := A_ScriptDir . "\Image\" . imageName . ".png"

    ; GDI+ 시작
    pToken := Gdip_Startup()

    ; 이미지 로드
    pBitmap := Gdip_CreateBitmapFromFile(imagePath)

    if (pBitmap)
    {
        ; 이미지 크기 가져오기
        width := Gdip_GetImageWidth(pBitmap)
        height := Gdip_GetImageHeight(pBitmap)

        ; 이미지 해제
        Gdip_DisposeImage(pBitmap)

        ; GDI+ 종료
        Gdip_Shutdown(pToken)

        return true
    }
    else
    {
        ; GDI+ 종료
        Gdip_Shutdown(pToken)
        return false
    }
}

; 이미지 찾아서 중앙 클릭
ClickAtCenterWhileFoundImage(imageName, findMaxCount := 10, delayTime := 1, searchStart_x := 0, searchStart_y := 0, searchEnd_x := -1, searchEnd_y := -1)
{
    ; 이미지 크기 가져오기
    GetImageSize(imageName, imgWidth, imgHeight)

    ; 이미지 중앙 오프셋 계산
    centerX := imgWidth // 2
    centerY := imgHeight // 2

    Debug("이미지 크기: " . imgWidth . "x" . imgHeight . ", 중앙 오프셋: (" . centerX . ", " . centerY . ")")

    ; 중앙 좌표로 클릭
    return ClickAtWhileFoundImage(imageName, centerX, centerY, findMaxCount, delayTime, searchStart_x, searchStart_y, searchEnd_x, searchEnd_y)
}

; URL 인코딩 함수
UriEncode(str) {
    static _enc := "UTF-8"
    VarSetCapacity(var, StrPut(str, _enc))
    StrPut(str, &var, _enc)
    f := A_FormatInteger
    SetFormat, IntegerFast, H
    Loop {
        code := NumGet(var, A_Index - 1, "UChar")
        if (!code)
            break
        ch := Chr(code)
        if (ch ~= "[0-9A-Za-z]")
            out .= ch
        else
            out .= "%" . SubStr("0" . SubStr(code, 3), -1)
    }
    SetFormat, IntegerFast, %f%
    return out
}

; 텔레그램 메시지 전송
TelegramSend(Message) {
    global TELEGRAM_CHAT_ID, TELEGRAM_BOT_TOKEN, TELEGRAM_MESSAGE_PREFIX

    Debug(Message)
    EncodedMessage := UriEncode("[" . TELEGRAM_MESSAGE_PREFIX . "] " . Message)
    Param := "chat_id=" . TELEGRAM_CHAT_ID . "&text=" . EncodedMessage
    URL := "https://api.telegram.org/bot" . TELEGRAM_BOT_TOKEN . "/sendmessage?"
    a := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    a.Open("POST", URL)
    a.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    a.Send(Param)
}

; ==========================================
; 랜덤 행동 패턴 함수 (매크로 회피)
; ==========================================

; 랜덤 스크롤 - 다양한 패턴으로 스크롤
RandomScroll()
{
    if (!g_RandomActionEnabled() || !g_ScrollVariationEnabled())
    {
        Debug("랜덤 스크롤 비활성화")
        return
    }

    Random, scrollPattern, 1, 100

    if (scrollPattern <= 50)
    {
        ; 50% - PgDn 4~12회 (4배)
        Random, count, 4, 12
        Debug("랜덤 스크롤: PgDn " . count . "회")
        Loop, %count%
        {
            Send, {PgDn}
            RandomDelay(0.5)
        }
    }
    else if (scrollPattern <= 80)
    {
        ; 30% - 휠 스크롤 여러 번 작게 (12~32회, 4배)
        Random, count, 12, 32
        Debug("랜덤 스크롤: 휠 다운 " . count . "회")
        Loop, %count%
        {
            Send, {WheelDown}
            RandomDelay(0.2)
        }
    }
    else
    {
        ; 20% - 위로 스크롤 후 아래로 (읽는 척, 4배)
        Debug("랜덤 스크롤: 위로 갔다가 아래로")
        Random, upCount, 4, 12
        Loop, %upCount%
        {
            Send, {WheelUp}
            RandomDelay(0.2)
        }
        RandomDelay(0.5)
        Random, downCount, 8, 20
        Loop, %downCount%
        {
            Send, {WheelDown}
            RandomDelay(0.2)
        }
    }
}

; 랜덤 정지 - 확률적으로 잠시 멈춤
RandomPause()
{
    if (!g_RandomActionEnabled() || !g_RandomPauseEnabled())
    {
        return
    }

    Random, rand, 1, 100
    probability := g_RandomActionProbability() * 100

    if (rand <= probability)
    {
        Random, pauseTime, 0.5, 2
        Debug("랜덤 정지: " . pauseTime . "초")
        RandomDelay(pauseTime)
    }
}

; 랜덤 마우스 이동 - 화면 내 랜덤 위치로 이동
RandomMouseMove()
{
    if (!g_RandomActionEnabled() || !g_RandomMouseMoveEnabled())
    {
        return
    }

    Random, rand, 1, 100
    probability := g_RandomActionProbability() * 100

    if (rand <= probability)
    {
        Random, moveX, 200, % A_ScreenWidth - 200
        Random, moveY, 200, % A_ScreenHeight - 200
        Debug("랜덤 마우스 이동: (" . moveX . ", " . moveY . ")")

        CoordMode, Mouse, Screen
        MouseMove, %moveX%, %moveY%, 50  ; 50 속도로 부드럽게 이동
        RandomDelay(0.3)
    }
}

; 랜덤 실수 행동 - 가끔 ESC, 뒤로가기 등
RandomMistake()
{
    if (!g_RandomActionEnabled() || !g_RandomMistakeEnabled())
    {
        return false
    }

    Random, rand, 1, 1000
    probability := g_RandomMistakeProbability() * 1000

    if (rand <= probability)
    {
        Random, mistakeType, 1, 2

        if (mistakeType = 1)
        {
            ; ESC 누르기
            Debug("랜덤 실수: ESC 키 입력")
            Send, {Esc}
            RandomDelay(0.5)
            return true
        }
        else
        {
            ; 뒤로가기 → 앞으로가기
            Debug("랜덤 실수: 뒤로가기 → 앞으로가기")
            Send, {Browser_Back}
            RandomDelay(1)
            Send, {Browser_Forward}
            RandomDelay(0.5)
            return true
        }
    }

    return false
}

; 읽는 척하기 - 텍스트 영역에서 마우스를 천천히 이동
RandomReading()
{
    if (!g_RandomActionEnabled() || !g_RandomMouseMoveEnabled())
    {
        return
    }

    Random, rand, 1, 100
    probability := g_RandomActionProbability() * 100

    if (rand <= probability)
    {
        Debug("랜덤 행동: 읽는 척하기")

        ; 현재 마우스 위치 가져오기
        MouseGetPos, startX, startY

        ; 아래쪽으로 천천히 이동하며 읽는 척
        Random, moveCount, 2, 5
        Loop, %moveCount%
        {
            Random, offsetX, -50, 50
            Random, offsetY, 20, 100
            newX := startX + offsetX
            newY := startY + (A_Index * offsetY)

            CoordMode, Mouse, Screen
            MouseMove, %newX%, %newY%, 30  ; 느린 속도로 이동
            RandomDelay(0.3)
        }
    }
}

; ==========================================
; 일일 한도 관리 함수
; ==========================================

; 오늘 날짜 가져오기 (YYYY-MM-DD 형식)
GetTodayDate()
{
    FormatTime, today, , yyyy-MM-dd
    return today
}

; 일일 랜덤 한도 파일 경로
GetDailyLimitFilePath()
{
    return A_ScriptDir . "\data\일일_한도.txt"
}

; 오늘의 랜덤 한도 가져오기 (하루에 한 번만 생성)
GetTodayRandomLimit()
{
    filePath := GetDailyLimitFilePath()
    today := GetTodayDate()

    ; data 폴더가 없으면 생성
    dataFolder := A_ScriptDir . "\data"
    if (!FileExist(dataFolder))
    {
        FileCreateDir, %dataFolder%
    }

    ; 파일이 있으면 확인
    if (FileExist(filePath))
    {
        FileRead, fileContent, %filePath%

        if (fileContent != "")
        {
            StringSplit, data, fileContent, `,
            savedDate := data1
            savedLimit := data2

            ; 오늘 날짜면 저장된 값 반환
            if (savedDate = today)
            {
                Debug("오늘 일일 한도: " . savedLimit . "개 (저장된 값)")
                return savedLimit
            }
        }
    }

    ; 새로운 날 - 랜덤 값 생성
    Random, newLimit, % g_DailyCommentLimitMin(), % g_DailyCommentLimitMax()

    ; 파일에 저장
    fileContent := today . "," . newLimit
    FileDelete, %filePath%
    FileAppend, %fileContent%, %filePath%

    Debug("새 일일 한도 생성: " . newLimit . "개 (범위: " . g_DailyCommentLimitMin() . "~" . g_DailyCommentLimitMax() . ")")
    return newLimit
}

; 일일 댓글 카운트 파일 경로
GetCommentCountFilePath()
{
    return A_ScriptDir . "\data\댓글_카운트.txt"
}

; 오늘의 댓글 개수 읽기
GetTodayCommentCount()
{
    filePath := GetCommentCountFilePath()
    today := GetTodayDate()

    ; 파일이 없으면 0 반환
    if (!FileExist(filePath))
    {
        Debug("댓글 카운트 파일 없음 - 0개로 시작")
        return 0
    }

    ; 파일 읽기
    FileRead, fileContent, %filePath%

    ; 파일이 비어있으면 0 반환
    if (fileContent = "")
    {
        Debug("댓글 카운트 파일 비어있음 - 0개로 시작")
        return 0
    }

    ; 날짜,카운트 형식으로 파싱
    StringSplit, data, fileContent, `,

    savedDate := data1
    savedCount := data2

    ; 저장된 날짜가 오늘이면 카운트 반환
    if (savedDate = today)
    {
        Debug("오늘 댓글 개수: " . savedCount . "개")
        return savedCount
    }
    else
    {
        ; 날짜가 다르면 0 반환 (새로운 날)
        Debug("새로운 날 시작 - 댓글 카운트 리셋")
        return 0
    }
}

; 댓글 카운트 증가 및 저장
IncrementCommentCount()
{
    filePath := GetCommentCountFilePath()
    today := GetTodayDate()

    ; 현재 카운트 가져오기
    currentCount := GetTodayCommentCount()

    ; 카운트 증가
    newCount := currentCount + 1

    ; 파일에 저장
    fileContent := today . "," . newCount

    ; data 폴더가 없으면 생성
    dataFolder := A_ScriptDir . "\data"
    if (!FileExist(dataFolder))
    {
        FileCreateDir, %dataFolder%
    }

    ; 파일 저장
    FileDelete, %filePath%
    FileAppend, %fileContent%, %filePath%

    Debug("댓글 카운트 증가: " . newCount . "개")
    return newCount
}

; 일일 한도 도달 여부 확인
CheckDailyLimit()
{
    if (!g_DailyLimitEnabled())
    {
        return false
    }

    currentCount := GetTodayCommentCount()

    ; 워밍업 중이면 워밍업 한도 사용
    limit := GetWarmupTodayLimit()

    if (currentCount >= limit)
    {
        Debug("일일 한도 도달! 현재: " . currentCount . "개 / 한도: " . limit . "개")
        return true
    }

    Debug("일일 한도 확인: " . currentCount . "/" . limit . "개")
    return false
}

; ==========================================
; 시간대별 활동 패턴 관리
; ==========================================

; 현재 시간이 활동 가능한 시간인지 확인
ShouldBeActiveNow()
{
    if (!g_TimeBasedActivityEnabled())
    {
        Debug("시간대별 활동 패턴 비활성화 - 항상 활동")
        return true
    }

    ; 현재 시간 가져오기 (0~23)
    FormatTime, currentHour, , HH
    currentHour := currentHour + 0  ; 문자열을 숫자로 변환

    ; 시간대별 확률 가져오기
    probability := GetActivityProbabilityByHour(currentHour)

    ; 확률이 0이면 무조건 비활성
    if (probability = 0)
    {
        Debug("현재 시간 " . currentHour . "시 - 비활성 시간대 (0%)")
        return false
    }

    ; 확률이 100이면 무조건 활성
    if (probability >= 100)
    {
        Debug("현재 시간 " . currentHour . "시 - 활성 시간대 (100%)")
        return true
    }

    ; 확률에 따라 랜덤 결정
    Random, rand, 1, 100

    if (rand <= probability)
    {
        Debug("현재 시간 " . currentHour . "시 - 활동 시작 (확률: " . probability . "%, 랜덤: " . rand . ")")
        return true
    }
    else
    {
        Debug("현재 시간 " . currentHour . "시 - 활동 대기 (확률: " . probability . "%, 랜덤: " . rand . ")")
        return false
    }
}

; 다음 활성 시간대까지 대기 시간 계산 (분 단위)
GetMinutesUntilNextActiveTime()
{
    ; 현재 시간
    FormatTime, currentHour, , HH
    FormatTime, currentMinute, , mm
    currentHour := currentHour + 0
    currentMinute := currentMinute + 0

    ; 다음 활성 시간대 찾기 (최대 24시간)
    Loop, 24
    {
        nextHour := Mod(currentHour + A_Index, 24)
        probability := GetActivityProbabilityByHour(nextHour)

        if (probability > 0)
        {
            ; 첫 번째 활성 시간대 발견
            if (A_Index = 1 && currentMinute < 59)
            {
                ; 같은 시간대 내에서 다음 시도까지의 시간
                return 60 - currentMinute
            }
            else
            {
                ; 다음 시간대까지의 시간 계산
                minutesUntil := (A_Index - 1) * 60 + (60 - currentMinute)
                Debug("다음 활성 시간대: " . nextHour . "시 (약 " . minutesUntil . "분 후)")
                return minutesUntil
            }
        }
    }

    ; 모든 시간대가 비활성 (이론적으로 불가능)
    return 60
}

; 세션 파일 경로
GetSessionFilePath()
{
    return A_ScriptDir . "\data\세션_정보.txt"
}

; 세션 시작 시간 저장
SaveSessionStartTime()
{
    filePath := GetSessionFilePath()
    FormatTime, now, , yyyy-MM-dd HH:mm:ss

    ; data 폴더가 없으면 생성
    dataFolder := A_ScriptDir . "\data"
    if (!FileExist(dataFolder))
    {
        FileCreateDir, %dataFolder%
    }

    ; 세션 시작 시간 + 세션 길이 (분) 저장
    Random, sessionLength, % g_SessionMinMinutes(), % g_SessionMaxMinutes()

    fileContent := now . "," . sessionLength

    FileDelete, %filePath%
    FileAppend, %fileContent%, %filePath%

    Debug("세션 시작: " . now . " (길이: " . sessionLength . "분)")
    return sessionLength
}

; 세션 시간 체크 (세션이 끝났는지 확인)
ShouldEndSession()
{
    if (!g_TimeBasedActivityEnabled())
    {
        return false
    }

    filePath := GetSessionFilePath()

    ; 파일이 없으면 새 세션 시작
    if (!FileExist(filePath))
    {
        SaveSessionStartTime()
        return false
    }

    ; 파일 읽기
    FileRead, fileContent, %filePath%

    if (fileContent = "")
    {
        SaveSessionStartTime()
        return false
    }

    ; 시작시간,세션길이 파싱
    StringSplit, data, fileContent, `,
    startTime := data1
    sessionLength := data2

    ; 현재 시간
    FormatTime, now, , yyyy-MM-dd HH:mm:ss

    ; 경과 시간 계산 (분)
    elapsedMinutes := GetMinutesBetween(startTime, now)

    if (elapsedMinutes >= sessionLength)
    {
        Debug("세션 종료: " . elapsedMinutes . "분 경과 (세션 길이: " . sessionLength . "분)")
        return true
    }

    Debug("세션 진행 중: " . elapsedMinutes . "/" . sessionLength . "분")
    return false
}

; 두 시간 사이의 분 차이 계산
GetMinutesBetween(time1, time2)
{
    ; time1: yyyy-MM-dd HH:mm:ss
    ; time2: yyyy-MM-dd HH:mm:ss

    ; 간단한 방법: 현재 시간과 비교
    ; AHK에서는 시간 차이 계산이 복잡하므로 TickCount 사용
    ; 여기서는 근사값 사용

    StringSplit, t1, time1, %A_Space%
    StringSplit, t2, time2, %A_Space%

    ; 시간 부분만 추출
    time1Hour := SubStr(t12, 1, 2) + 0
    time1Minute := SubStr(t12, 4, 2) + 0

    time2Hour := SubStr(t22, 1, 2) + 0
    time2Minute := SubStr(t22, 4, 2) + 0

    ; 분으로 변환
    minutes1 := time1Hour * 60 + time1Minute
    minutes2 := time2Hour * 60 + time2Minute

    ; 차이 계산
    diff := minutes2 - minutes1

    ; 날짜가 바뀐 경우 처리
    if (diff < 0)
    {
        diff += 1440  ; 24시간 = 1440분
    }

    return diff
}

; ==========================================
; 워밍업 기간 관리
; ==========================================

; 워밍업 파일 경로
GetWarmupFilePath()
{
    return A_ScriptDir . "\data\워밍업_시작일.txt"
}

; 워밍업 시작
StartWarmup()
{
    if (!g_WarmupEnabled())
    {
        Debug("워밍업 기간 기능이 비활성화되어 있습니다")
        return false
    }

    filePath := GetWarmupFilePath()
    FormatTime, today, , yyyy-MM-dd

    ; data 폴더가 없으면 생성
    dataFolder := A_ScriptDir . "\data"
    if (!FileExist(dataFolder))
    {
        FileCreateDir, %dataFolder%
    }

    ; 워밍업 시작일 저장
    FileDelete, %filePath%
    FileAppend, %today%, %filePath%

    Debug("워밍업 시작: " . today)

    ; 텔레그램 알림
    warmupDays := g_WarmupDays()
    firstDayLimit := GetWarmupTodayLimit()
    TelegramSend("🔥 워밍업 시작!" . "`n" . "향후 " . warmupDays . "일간 천천히 활동량을 늘립니다." . "`n" . "1일차 한도: " . firstDayLimit . "개")

    return true
}

; 워밍업 종료
EndWarmup()
{
    filePath := GetWarmupFilePath()

    if (FileExist(filePath))
    {
        FileDelete, %filePath%
        Debug("워밍업 종료")

        ; 텔레그램 알림
        normalLimit := g_DailyCommentLimit()
        TelegramSend("✅ 워밍업 완료!" . "`n" . "정상 활동 시작 (한도: " . normalLimit . "개)")

        return true
    }

    return false
}

; 워밍업 진행 중인지 확인
IsWarmupActive()
{
    if (!g_WarmupEnabled())
    {
        return false
    }

    filePath := GetWarmupFilePath()

    if (!FileExist(filePath))
    {
        return false
    }

    ; 워밍업 시작일 읽기
    FileRead, startDate, %filePath%

    if (startDate = "")
    {
        return false
    }

    ; 경과 일수 계산
    elapsedDays := GetDaysBetween(startDate, GetTodayDate())

    ; 워밍업 기간이 지났으면 자동 종료
    if (elapsedDays >= g_WarmupDays())
    {
        Debug("워밍업 기간 종료 (경과: " . elapsedDays . "일)")
        EndWarmup()
        return false
    }

    return true
}

; 워밍업 경과 일수 가져오기 (1일차부터)
GetWarmupDay()
{
    if (!IsWarmupActive())
    {
        return 0
    }

    filePath := GetWarmupFilePath()
    FileRead, startDate, %filePath%

    ; 경과 일수 + 1 (1일차부터 시작)
    elapsedDays := GetDaysBetween(startDate, GetTodayDate())
    return elapsedDays + 1
}

; 워밍업 시작일 가져오기
GetWarmupStartDate()
{
    if (!IsWarmupActive())
    {
        return ""
    }

    filePath := GetWarmupFilePath()
    FileRead, startDate, %filePath%
    return startDate
}

; 워밍업 중 오늘의 한도 계산
GetWarmupTodayLimit()
{
    if (!IsWarmupActive())
    {
        return GetTodayRandomLimit()
    }

    day := GetWarmupDay()
    percent := GetWarmupDayPercent(day)
    normalLimit := GetTodayRandomLimit()

    ; 비율 적용
    warmupLimit := Floor(normalLimit * percent / 100)

    Debug("워밍업 D+" . day . " - 한도: " . warmupLimit . "개 (" . percent . "%)")

    return warmupLimit
}

; 두 날짜 사이의 일수 차이 계산
GetDaysBetween(date1, date2)
{
    ; date1: yyyy-MM-dd
    ; date2: yyyy-MM-dd

    ; 간단한 날짜 차이 계산
    ; yyyy-MM-dd 형식을 yyyyMMdd로 변환
    StringReplace, d1, date1, -, , All
    StringReplace, d2, date2, -, , All

    ; EnvSub으로 일수 차이 계산
    d1 += 0, days
    d2 += 0, days
    EnvSub, d2, %d1%, days

    return d2
}

; 자동 워밍업 체크 (3일 이상 댓글 0개인 경우)
CheckAutoWarmup()
{
    if (!g_WarmupEnabled())
    {
        return false
    }

    ; 이미 워밍업 중이면 스킵
    if (IsWarmupActive())
    {
        return false
    }

    ; 최근 3일간 댓글 개수 확인
    ; 간단히 오늘 댓글이 0개이고 파일이 3일 이상 오래되었는지 확인
    filePath := GetCommentCountFilePath()

    if (!FileExist(filePath))
    {
        ; 파일이 없으면 처음 사용 - 워밍업 시작
        Debug("첫 사용 감지 - 워밍업 자동 시작")
        StartWarmup()
        return true
    }

    FileRead, fileContent, %filePath%

    if (fileContent = "")
    {
        return false
    }

    StringSplit, data, fileContent, `,
    savedDate := data1
    savedCount := data2

    ; 오늘 날짜와 비교
    today := GetTodayDate()
    daysDiff := GetDaysBetween(savedDate, today)

    ; 3일 이상 활동이 없었으면 워밍업 시작
    if (daysDiff >= 3)
    {
        Debug("3일 이상 활동 없음 - 워밍업 자동 시작")
        StartWarmup()
        return true
    }

    return false
}

; ==========================================
; 성공 기반 간격 분배 함수
; ==========================================

; 남은 시간 계산 (분 단위)
GetRemainingActiveMinutes()
{
    ; 현재 시간
    FormatTime, currentHour, , HH
    FormatTime, currentMinute, , mm
    currentHour := currentHour + 0
    currentMinute := currentMinute + 0

    ; 활동 종료 시간
    endHour := g_ActivityEndHour()

    ; 남은 분 계산
    if (currentHour >= endHour)
    {
        ; 이미 종료 시간 지남
        return 0
    }

    remainingMinutes := (endHour - currentHour) * 60 - currentMinute
    return remainingMinutes
}

; 성공 후 대기 시간 계산 (분 단위)
CalculateSuccessWaitTime()
{
    if (!g_SuccessBasedIntervalEnabled())
    {
        return 0
    }

    ; 남은 댓글 수
    currentCount := GetTodayCommentCount()
    limit := GetWarmupTodayLimit()
    remainingComments := limit - currentCount

    if (remainingComments <= 0)
    {
        Debug("남은 댓글 없음 - 대기 시간 0")
        return 0
    }

    ; 남은 활동 시간 (분)
    remainingMinutes := GetRemainingActiveMinutes()

    if (remainingMinutes <= 0)
    {
        Debug("활동 종료 시간 지남 - 대기 시간 0")
        return 0
    }

    ; 기본 간격 계산
    baseInterval := remainingMinutes / remainingComments
    Debug("기본 간격: " . baseInterval . "분 (남은 시간: " . remainingMinutes . "분, 남은 댓글: " . remainingComments . "개)")

    ; 시간대별 확률에 따른 조절
    FormatTime, currentHour, , HH
    currentHour := currentHour + 0
    probability := GetActivityProbabilityByHour(currentHour)

    ; 확률에 따른 간격 조절 (확률 높으면 짧게, 낮으면 길게)
    if (probability >= 90)
    {
        intervalMultiplier := 0.8  ; 활발한 시간대: 더 짧게
    }
    else if (probability >= 70)
    {
        intervalMultiplier := 0.9
    }
    else if (probability >= 50)
    {
        intervalMultiplier := 1.2  ; 보통 시간대: 더 길게
    }
    else if (probability >= 30)
    {
        intervalMultiplier := 1.5
    }
    else
    {
        intervalMultiplier := 2.0  ; 비활성 시간대: 훨씬 길게
    }

    adjustedInterval := baseInterval * intervalMultiplier
    Debug("시간대 조절: " . adjustedInterval . "분 (확률: " . probability . "%, 배수: " . intervalMultiplier . ")")

    ; 랜덤 변동 추가
    minRatio := g_IntervalMinRatio()
    maxRatio := g_IntervalMaxRatio()

    ; 소수점을 위해 100을 곱해서 계산
    Random, randomRatio, % Floor(minRatio * 100), % Floor(maxRatio * 100)
    randomRatio := randomRatio / 100

    finalInterval := adjustedInterval * randomRatio
    Debug("랜덤 변동: " . finalInterval . "분 (비율: " . randomRatio . ")")

    ; 최소/최대 제한 적용
    if (finalInterval < g_MinWaitMinutes())
    {
        finalInterval := g_MinWaitMinutes()
        Debug("최소 대기 시간 적용: " . finalInterval . "분")
    }

    if (finalInterval > g_MaxWaitMinutes())
    {
        finalInterval := g_MaxWaitMinutes()
        Debug("최대 대기 시간 적용: " . finalInterval . "분")
    }

    return Floor(finalInterval)
}

; 성공 후 대기 (카운트다운 포함)
WaitAfterSuccess()
{
    if (!g_SuccessBasedIntervalEnabled())
    {
        return true
    }

    ; 현재 시간대 가져오기
    FormatTime, currentHour, , HH
    currentHour := currentHour + 0

    ; 시간대별 활동 확률 가져오기
    probability := GetActivityProbabilityByHour(currentHour)

    ; 활동 확률에 따른 대기 시간 범위 설정
    minWait := g_MinWaitMinutes()
    maxWait := g_MaxWaitMinutes()

    if (probability >= 80)
    {
        ; 활동 확률 높음 (80~90%) - 짧은 대기 (5~15분)
        Random, waitMinutes, %minWait%, 15
        Debug("활동 확률 높음 (" . probability . "%) - 짧은 대기")
    }
    else if (probability >= 60)
    {
        ; 활동 확률 중간 (60~79%) - 중간 대기 (10~20분)
        Random, waitMinutes, 10, 20
        Debug("활동 확률 중간 (" . probability . "%) - 중간 대기")
    }
    else if (probability >= 20)
    {
        ; 활동 확률 낮음 (20~59%) - 긴 대기 (15~30분)
        Random, waitMinutes, 15, %maxWait%
        Debug("활동 확률 낮음 (" . probability . "%) - 긴 대기")
    }
    else
    {
        ; 활동 확률 매우 낮음 (0~19%) - 최대 대기 (20~30분)
        Random, waitMinutes, 20, %maxWait%
        Debug("활동 확률 매우 낮음 (" . probability . "%) - 최대 대기")
    }

    ; 재개 예정 시각 계산
    resumeTime := A_Now
    resumeTime += waitMinutes, Minutes
    FormatTime, resumeTimeFormatted, %resumeTime%, HH:mm:ss

    Debug("성공 후 대기 시작 - " . waitMinutes . "분 (시간대: " . currentHour . "시, 활동확률: " . probability . "%, 재개 예정: " . resumeTimeFormatted . ")")

    ; 텔레그램 알림
    currentCount := GetTodayCommentCount()
    limit := GetWarmupTodayLimit()
    remainingComments := limit - currentCount
    TelegramSend("⏰ " . waitMinutes . "분 대기 후 다음 시도" . "`n" . "남은 댓글: " . remainingComments . "개" . "`n" . "재개 예정: " . resumeTimeFormatted)

    ; 초 단위 카운트다운
    waitSeconds := waitMinutes * 60
    Loop, %waitSeconds%
    {
        global isRunning
        if (!isRunning)
        {
            GuiControl,, Status, 중지됨
            GuiControl,, Progress, 작업이 중지되었습니다.
            Debug("성공 후 대기 중 작업 중지됨")
            return false
        }

        remainingSeconds := waitSeconds - A_Index + 1

        ; 분:초로 표시
        remainingMinutesDisplay := Floor(remainingSeconds / 60)
        remainingSecondsOnly := Mod(remainingSeconds, 60)
        GuiControl,, Progress, 다음 댓글까지 대기 중... (남은 시간: %remainingMinutesDisplay%분 %remainingSecondsOnly%초)

        Sleep, 1000  ; 1초 대기
    }

    Debug("성공 후 대기 완료 - 다음 시도 시작")
    return true
}

; ==========================================
; 수동 참여 링크 관리 함수
; ==========================================

; 수동 참여 링크를 파일에 저장 (중복 체크 포함)
SaveManualParticipationLink(link)
{
    filePath := A_ScriptDir . "\data\수동참여링크.txt"

    ; 파일이 존재하면 기존 링크 읽기
    existingLinks := []
    if (FileExist(filePath))
    {
        FileRead, fileContent, %filePath%

        ; 줄 단위로 분리하여 배열에 저장
        Loop, Parse, fileContent, `n, `r
        {
            existingLink := Trim(A_LoopField)
            if (existingLink != "")
            {
                existingLinks.Push(existingLink)
            }
        }

        Debug("기존 수동 참여 링크 " . existingLinks.Length() . "개 로드 완료")
    }
    else
    {
        Debug("수동 참여 링크 파일이 없습니다. 새로 생성합니다.")
    }

    ; 중복 체크
    for index, existingLink in existingLinks
    {
        if (existingLink = link)
        {
            Debug("중복된 링크 발견 - 저장하지 않음: " . link)
            return false
        }
    }

    ; 중복이 아니면 파일에 추가
    FileAppend, %link%`n, %filePath%, UTF-8

    if (ErrorLevel)
    {
        Debug("수동 참여 링크 저장 실패: " . link)
        return false
    }

    Debug("수동 참여 링크 저장 완료: " . link)
    return true
}
