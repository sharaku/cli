#!/bin/bash
########################################################################
#
# 起動すると、入力待ち ⇔ 入力されたコマンドを実行 を繰り返す
# コマンドは、cliディレクトリを検索して実行する
#
########################################################################

# 現在のパスを元に環境変数を読み込む
export readonly DEF_CLI_PATH=`dirname ${0}`

. ${DEF_CLI_PATH}/configure
. ${DEF_CLI_PATH}/env

# ----------------------------------------------------------------------
# 変数定義
# ----------------------------------------------------------------------
readonly DEF_HELP_FILE=help.txt

# ----------------------------------------------------------------------
# サブルーチン
# ----------------------------------------------------------------------

# trap handler
traphandler() {
  # disable SIG* inside this handler
  echo "Please use the Exit command if you want to end."
  echo -n "${DEF_CLIPROMPT} "
}

# ディレクトリに格納されているヘルプを表示する
# ファイルは以下の形式となる
# コマンド名<tab>説明
show_help() {
  help_file=${1}
  # ヘッダ部分を表示する
  printf %-32s "command"
  echo "summary"
  echo "----------------------------------------------------------------------"

  # ファイルからデータを読み取って表示する
  while read line
  do
    command_name=`echo -e "${line}" | cut -f 1`
    help_text=`echo -e "${line}" | cut -f 2`
    printf %-32s "${command_name}"
    echo "${help_text}"
  done < ${help_file}
}

# command exec
command_exec() {
  request_commnad=${*}
  cli_path=${DEF_COMMAND_PATH}
  cli_command=${1}
  shift
  
  case ${cli_command} in
    "exit" )
      exit 0
      ;;

    "" )
      ;;

    "help" )
      # コマンドを取り出す。
      # helpのみ指定されていた場合はhelp.shを呼び出す
      cli_command=${1}
      shift
      if [ "${cli_command}" == "" ]; then
        show_help ${DEF_COMMAND_PATH}/${DEF_HELP_FILE}
        return 0
      fi

      # 先頭のコマンドから順に評価する
      # ディレクトリを指している場合は、そのディレクトリのhelp.shを呼び出す。
      # ファイルを指している場合は、そのコマンドに対して--helpを引数として呼び出す
      while :
      do
        if [ -f "${cli_path}${cli_command}" ]; then
          ${cli_path}${cli_command} --help
          break
        else
          cli_path=${cli_path}${cli_command}/

          # 次のコマンドを取得する
          # コマンドがない場合はhelpを呼び出す
          cli_command=${1}
          shift
          if [ "${cli_command}" == "" ]; then
            show_help ${cli_path}/${DEF_HELP_FILE}
            break
          elif [ "${cli_command}" == "help.sh" ]; then
            show_help ${cli_path}/${DEF_HELP_FILE}
            break
          fi
        fi
      done
      ;;

    * )
      # 先頭のコマンドから順に評価する
      # ディレクトリを辿ってコマンドまで行き着いたらコマンドを実行する
      while :
      do
        if [ -f "${cli_path}${cli_command}" ]; then
          break
        elif [ ! -e "${cli_path}${cli_command}" ]; then
            echo "\"${request_commnad}\" command is not found."
            return 0
        else
          cli_path=${cli_path}${cli_command}/

          # 次のコマンドを取得する
          # コマンドがない場合はhelpを呼び出す
          cli_command=${1}
          shift
          if [ "${cli_command}" == "" ]; then
            show_help ${cli_path}/${DEF_HELP_FILE}
            return 0
          elif [ "${cli_command}" == "help.sh" ]; then
            show_help ${cli_path}/${DEF_HELP_FILE}
            return 0
          fi
        fi
      done
      ${cli_path}${cli_command} $*
      ;;
  esac
  return 0
}

# ----------------------------------------------------------------------
# main
# ----------------------------------------------------------------------

trap "traphandler $*" 2

while :
do
  echo -n "${DEF_CLIPROMPT} "
  read command
  command_exec ${command}
done


