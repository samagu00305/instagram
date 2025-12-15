; 환경 변수 로더
; .env 파일을 읽어서 전역 변수로 설정합니다.

; 파일 인코딩 설정 (한글 깨짐 방지)
FileEncoding, UTF-8

; .env 파일 경로
envFilePath := A_ScriptDir . "\.env"

; .env 파일이 없으면 에러
if (!FileExist(envFilePath))
{
    MsgBox, 16, 환경 변수 오류, .env 파일을 찾을 수 없습니다.`n`n.env.example 파일을 복사하여 .env로 이름을 변경하고`n실제 값으로 수정해주세요.
    ExitApp
}

; .env 파일 읽기
FileRead, envContent, %envFilePath%

; 줄 단위로 파싱
Loop, Parse, envContent, `n, `r
{
    line := Trim(A_LoopField)

    ; 빈 줄이나 주석(#으로 시작)은 건너뛰기
    if (line = "" || SubStr(line, 1, 1) = "#")
        continue

    ; KEY=VALUE 형식 파싱
    pos := InStr(line, "=")
    if (pos > 0)
    {
        key := Trim(SubStr(line, 1, pos - 1))
        value := Trim(SubStr(line, pos + 1))

        ; 값의 앞뒤 따옴표 제거 (있는 경우)
        if (SubStr(value, 1, 1) = """" && SubStr(value, 0, 1) = """")
            value := SubStr(value, 2, StrLen(value) - 2)
        else if (SubStr(value, 1, 1) = "'" && SubStr(value, 0, 1) = "'")
            value := SubStr(value, 2, StrLen(value) - 2)

        ; 전역 변수로 설정
        if (key = "TELEGRAM_BOT_TOKEN")
            global TELEGRAM_BOT_TOKEN := value
        else if (key = "TELEGRAM_CHAT_ID")
            global TELEGRAM_CHAT_ID := value
        else if (key = "TELEGRAM_MESSAGE_PREFIX")
            global TELEGRAM_MESSAGE_PREFIX := value
        else if (key = "MANUAL_PARTICIPATION_ALERT_ENABLED")
            global MANUAL_PARTICIPATION_ALERT_ENABLED := value
        else if (key = "AI_PRIORITY")
            global AI_PRIORITY := value
    }
}

; 필수 변수 체크
if (TELEGRAM_BOT_TOKEN = "" || TELEGRAM_CHAT_ID = "")
{
    MsgBox, 16, 환경 변수 오류, .env 파일에 필수 값이 설정되지 않았습니다.`n`nTELEGRAM_BOT_TOKEN과 TELEGRAM_CHAT_ID를 설정해주세요.
    ExitApp
}
