; 전역 변수 및 상수 정의

; 파일 인코딩 설정 (한글 깨짐 방지)
FileEncoding, UTF-8

; 에러 타입
g_ErrorType_Success()
{
    return 0
}

; 1초 = 1000ms
g_OneSecond()
{
    return 1000
}

; 기본 경로
g_DefaultPath()
{
    return A_ScriptDir
}

; 디버그 모드
g_DebugMode()
{
    return true
}

; 재시도 대기 시간 (초 단위) - 실패 시
g_RetryDelaySeconds()
{
    return 4
}

; 성공 후 다음 게시물 대기 시간 (초 단위)
g_NextPostDelaySeconds()
{
    return 4
}

; ==========================================
; 랜덤 딜레이 설정
; ==========================================

; 랜덤 딜레이 활성화 여부 (true: 켜기, false: 끄기)
g_RandomDelayEnabled()
{
    return true
}

; 랜덤 딜레이 변동폭 비율 (예: 0.3 = 기준시간의 ±30%)
; 예) 기준 시간이 10초이고 비율이 0.3이면 → 7초~13초 사이 랜덤
g_RandomDelayVariationRatio()
{
    return 0.3
}

; 랜덤 딜레이 최소 변동 시간 (초 단위)
; 아무리 기준 시간이 짧아도 최소한 이만큼은 변동
g_RandomDelayMinVariation()
{
    return 1
}

; 랜덤 딜레이 최대 변동 시간 (초 단위)
; 아무리 기준 시간이 길어도 변동폭은 이 값을 넘지 않음
g_RandomDelayMaxVariation()
{
    return 5
}

; ==========================================
; 랜덤 행동 패턴 설정 (매크로 회피)
; ==========================================

; 랜덤 행동 패턴 활성화 여부 (true: 켜기, false: 끄기)
g_RandomActionEnabled()
{
    return true
}

; 랜덤 행동 발생 확률 (0.0 ~ 1.0, 예: 0.3 = 30%)
g_RandomActionProbability()
{
    return 0.3
}

; 스크롤 패턴 다양화 활성화
g_ScrollVariationEnabled()
{
    return true
}

; 랜덤 마우스 이동 활성화
g_RandomMouseMoveEnabled()
{
    return true
}

; 랜덤 정지 활성화
g_RandomPauseEnabled()
{
    return true
}

; 가끔 실수 행동 활성화 (뒤로가기, ESC 등)
g_RandomMistakeEnabled()
{
    return false  ; 작업 완료 후 뒤로가기로 인한 화면 꼬임 방지를 위해 비활성화
}

; 실수 행동 발생 확률 (0.0 ~ 1.0, 예: 0.05 = 5%)
g_RandomMistakeProbability()
{
    return 0.05
}

; ==========================================
; 일일 한도 제한 설정
; ==========================================

; 일일 댓글 한도 활성화 여부
g_DailyLimitEnabled()
{
    return true
}

; 하루 최대 댓글 개수 (최소값)
g_DailyCommentLimitMin()
{
    return 35
}

; 하루 최대 댓글 개수 (최대값)
g_DailyCommentLimitMax()
{
    return 40
}

; 하루 최대 댓글 개수 (기본값 - 하위 호환성을 위해 유지)
g_DailyCommentLimit()
{
    return 40
}

; ==========================================
; 성공 기반 간격 분배 설정
; ==========================================

; 성공 기반 간격 분배 활성화 여부
g_SuccessBasedIntervalEnabled()
{
    return true
}

; 활동 종료 시간 (24시간 형식, 예: 21 = 저녁 9시)
g_ActivityEndHour()
{
    return 21
}

; 간격 최소 변동 비율 (예: 0.7 = 70%)
g_IntervalMinRatio()
{
    return 0.7
}

; 간격 최대 변동 비율 (예: 1.3 = 130%)
g_IntervalMaxRatio()
{
    return 1.3
}

; 최소 대기 시간 (분) - 아무리 짧아도 이 시간은 대기
g_MinWaitMinutes()
{
    return 5
}

; 최대 대기 시간 (분) - 아무리 길어도 이 시간 넘지 않음
g_MaxWaitMinutes()
{
    return 30
}

; ==========================================
; 시간대별 활동 패턴 설정 (직장인 패턴)
; ==========================================

; 시간대별 활동 패턴 활성화 여부
g_TimeBasedActivityEnabled()
{
    return true
}

; 한 세션 최소 작업 시간 (분)
g_SessionMinMinutes()
{
    return 60
}

; 한 세션 최대 작업 시간 (분)
g_SessionMaxMinutes()
{
    return 120
}

; 세션 사이 최소 휴식 시간 (분)
g_SessionBreakMinMinutes()
{
    return 15
}

; 세션 사이 최대 휴식 시간 (분)
g_SessionBreakMaxMinutes()
{
    return 30
}

; 시간대별 휴식 시간 설정 (최소, 최대 분 반환)
; hour: 0~23 (24시간 형식)
; 반환: "최소,최대" 형식의 문자열
GetSessionBreakByHour(hour)
{
    ; 00:00~06:00 - 수면 시간 (수면 대기로 처리됨, 여기 도달 안 함)
    ; 06:00~09:00 - 기상~출근 (긴 휴식)
    if (hour >= 6 && hour < 9)
        return "25,30"

    ; 09:00~12:00 - 오전 업무, 활발 (짧은 휴식)
    if (hour >= 9 && hour < 12)
        return "15,20"

    ; 12:00~14:00 - 점심시간 (13:30까지이지만 시간 단위라 14시로 설정)
    if (hour >= 12 && hour < 14)
        return "15,25"

    ; 14:00~18:00 - 오후 업무 (비활성, 여기 도달 안 함)
    ; 18:00~21:00 - 퇴근 후, 활발 (짧은 휴식)
    if (hour >= 18 && hour < 21)
        return "15,25"

    ; 21:00~24:00 - 저녁/취침 전 (긴 휴식)
    if (hour >= 21 && hour < 24)
        return "25,30"

    return "15,30"
}

; 시간대별 활동 확률 반환 (0~100)
; hour: 0~23 (24시간 형식)
GetActivityProbabilityByHour(hour)
{
    ; 주말 체크 (토요일=7, 일요일=1)
    FormatTime, dayOfWeek, , WDay
    isWeekend := (dayOfWeek = 1 || dayOfWeek = 7)

    ; 00:00~06:00 - 수면 시간 (0%)
    if (hour >= 0 && hour < 6)
        return 0

    ; 주말인 경우 - 점심 낮잠 시간 있음
    if (isWeekend)
    {
        ; 일일 랜덤 오프셋 가져오기 (주말 낮잠 시간 변동)
        offsets := GetDailyTimeOffsets()
        napStartOffset := offsets.napStart  ; -1 ~ +1 시간
        napEndOffset := offsets.napEnd      ; -1 ~ +1 시간

        ; 주말 낮잠 시간 (기본: 13:00~15:00)
        napStart := 13 + napStartOffset  ; 12~14시
        napEnd := 15 + napEndOffset      ; 14~16시

        ; 06:00~09:00 - 늦잠 (20%)
        if (hour >= 6 && hour < 9)
            return 20

        ; 09:00~12:00 - 오전 (70%)
        if (hour >= 9 && hour < 12)
            return 70

        ; 12:00~낮잠시작 - 점심 (70%)
        if (hour >= 12 && hour < napStart)
            return 70

        ; 낮잠시작~낮잠끝 - 낮잠 시간 (0% - 비활성)
        if (hour >= napStart && hour < napEnd)
            return 0

        ; 낮잠끝~18:00 - 오후 (70%)
        if (hour >= napEnd && hour < 18)
            return 70

        ; 18:00~21:00 - 저녁 (80%)
        if (hour >= 18 && hour < 21)
            return 80

        ; 21:00~24:00 - 밤 (30%)
        if (hour >= 21 && hour < 24)
            return 30

        return 0
    }

    ; 평일인 경우
    ; 일일 랜덤 오프셋 가져오기 (오후 업무 시작/종료 시간 변동)
    offsets := GetDailyTimeOffsets()
    afternoonStartOffset := offsets.afternoonStart  ; -1 ~ +1 시간
    afternoonEndOffset := offsets.afternoonEnd      ; -1 ~ +1 시간

    ; 오후 업무 시작/종료 시간 (기본: 14:00~18:00)
    afternoonStart := 14 + afternoonStartOffset  ; 13~15시
    afternoonEnd := 18 + afternoonEndOffset      ; 17~19시

    ; 06:00~09:00 - 기상~출근 (20%)
    if (hour >= 6 && hour < 9)
        return 20

    ; 09:00~12:00 - 오전 업무, 이벤트 많음 (90%)
    if (hour >= 9 && hour < 12)
        return 90

    ; 12:00~오후업무시작 - 점심시간 (70%)
    if (hour >= 12 && hour < afternoonStart)
        return 70

    ; 오후업무시작~오후업무끝 - 오후 업무 (0% - 비활성)
    if (hour >= afternoonStart && hour < afternoonEnd)
        return 0

    ; 오후업무끝~21:00 - 퇴근 후, 활발 (80%)
    if (hour >= afternoonEnd && hour < 21)
        return 80

    ; 21:00~24:00 - 저녁/취침 전 (30%)
    if (hour >= 21 && hour < 24)
        return 30

    return 0
}

; 날짜 기반 일일 랜덤 오프셋 생성
; 같은 날에는 항상 같은 오프셋 반환 (하루 동안 일관성 유지)
GetDailyTimeOffsets()
{
    global g_DailyTimeOffsets, g_DailyTimeOffsetsDate

    ; 오늘 날짜
    FormatTime, today, , yyyyMMdd

    ; 이미 오늘의 오프셋이 있으면 그대로 반환
    if (g_DailyTimeOffsetsDate = today && IsObject(g_DailyTimeOffsets))
    {
        return g_DailyTimeOffsets
    }

    ; 새로운 일일 오프셋 생성
    Random, afternoonStartOffset, -1, 1  ; 오후 업무 시작: 13~15시
    Random, afternoonEndOffset, -1, 1    ; 오후 업무 종료: 17~19시
    Random, napStartOffset, -1, 1        ; 주말 낮잠 시작: 12~14시
    Random, napEndOffset, -1, 1          ; 주말 낮잠 종료: 14~16시

    g_DailyTimeOffsets := {afternoonStart: afternoonStartOffset, afternoonEnd: afternoonEndOffset, napStart: napStartOffset, napEnd: napEndOffset}
    g_DailyTimeOffsetsDate := today

    ; 주말 체크
    FormatTime, dayOfWeek, , WDay
    isWeekend := (dayOfWeek = 1 || dayOfWeek = 7)

    if (isWeekend)
    {
        Debug("일일 시간 오프셋 생성 (주말) - 낮잠 시작: " . (13 + napStartOffset) . "시, 종료: " . (15 + napEndOffset) . "시")
    }
    else
    {
        Debug("일일 시간 오프셋 생성 (평일) - 오후업무 시작: " . (14 + afternoonStartOffset) . "시, 종료: " . (18 + afternoonEndOffset) . "시")
    }

    return g_DailyTimeOffsets
}

; ==========================================
; 텔레그램 알림 설정
; ==========================================

; 수동 참여 필요 이벤트 텔레그램 알림 활성화 여부
; true: 수동 참여가 필요한 이벤트 발견 시 텔레그램으로 링크 전송
; false: 수동 참여가 필요한 이벤트는 조용히 스킵만 함
g_TelegramManualParticipationNotificationEnabled()
{
    return false
}

; ==========================================
; 워밍업 기간 설정
; ==========================================

; 워밍업 기간 활성화 여부
g_WarmupEnabled()
{
    return false
}

; 워밍업 기간 (일 단위)
g_WarmupDays()
{
    return 7
}

; 일자별 한도 비율 (%) - 1일차부터 7일차까지
; 예: [25, 35, 50, 65, 80, 90, 100]
GetWarmupDayPercent(day)
{
    if (day <= 0)
        return 100

    if (day = 1)
        return 25
    if (day = 2)
        return 35
    if (day = 3)
        return 50
    if (day = 4)
        return 65
    if (day = 5)
        return 80
    if (day = 6)
        return 90

    ; 7일차 이후는 100%
    return 100
}
