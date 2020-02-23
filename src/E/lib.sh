#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#DIR_TOP=$( echo pwd)
DIR_TOP=$PWD

#DOTSIM=',' # разделитель параметров в имени тестового файла
#TMP_DIR=~/tmp
#TMP_DIR=./T
TMP_DIR=$DIR_TOP/T

#-------------------------------------------------------------------------------
tst () 
{

  LL=$1   # префикс тестового задания
  OUT=$2
  DIR_CMD=$3
  CMD=$4  # само задание (команда)

  CMD_TRUE=$( echo ${CMD//'^'/'/'} ) 
  #echo "$CMD_TRUE"

  # формируем имя файла, заменяя пробелы разделителями 
  T_FILE=$( echo ${CMD// /,} ) 

  N_FILE=$( echo "$LL:$T_FILE" ) 
  echo "$LL: $CMD ..."

  eval ${DIR_CMD}/$CMD_TRUE > $OUT/$N_FILE  2> /dev/null
  # eval $CMD &> $OUT/$N_FILE 

}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
run_tests () 
{

  LEVEL=$1
  DIR_TST=$2
  DIR_CMD=$3

#echo $DIR_TOP

for TRUE_FILE in ${DIR_TST}/*               # цикл по всем файлам в указанной директории
  do
    T_FILE=`basename $TRUE_FILE`       # зачищаем имя файла от путей

#     LL=`echo "$T_FILE" | awk 'BEGIN{FS=":"} {print $1}'` # отделяем метку уровня    
#     RR=`echo "$T_FILE" | awk 'BEGIN{FS=":"} {print $2}'` # от непосредственно задания

    LL=`echo "$T_FILE" | awk 'BEGIN{FS="%"} {print $1}'` # отделяем метку уровня    
    RR=`echo "$T_FILE" | awk 'BEGIN{FS="%"} {print $2}'` # от непосредственно задания

    # если не тот уровень, то пропустить обработку ..
    if [ "$LL" != "$LEVEL" ]
    then
        continue
    fi

    echo -n "$T_FILE ... "  # печатаем полученное имя

    # и формируем команду, заменяя ВСЕ разделители пробелами:
    # CMD=$( echo ${RR//$DOTSIM/ } )  # ошибка на F11 : bad substitution
    # CMD=`echo $RR | sed -e "s/,/ /g"` # а так проходит!

    #--------------!!!!!
    CMD=$( echo ${RR//'^'/'/'} )   # сначала (!) подменяем спец-символы директорий
    CMD=$( echo ${CMD//','/' '} )  # а потом спец-символы пробелов
    #--------------!!!!!

    # переменная $$ хранит id процесса сценария
    #CALC_FILE=$TMP_DIR/$$.$T_FILE.calc   # имя временного тестового файла 
    #DIFF_FILE=$TMP_DIR/$$.$T_FILE.diff   # имя временного файла сравнения 

    CALC_FILE=$TMP_DIR/a_CALC   # имя временного тестового файла 
    DIFF_FILE=$TMP_DIR/a_DIFF   # имя временного файла сравнения 

   #(CALC_FILE     (concatenate 'string dir_tmp "/a_CALC"))
   #(CALC_FILE_SED (concatenate 'string dir_tmp "/a_CALC_SED"))
   #(TRUE_FILE_SED (concatenate 'string dir_tmp "/a_TRUE_SED"))
   #(DIFF_FILE     (concatenate 'string dir_tmp "/a_DIFF"))
                                 
    # выполняем задание, перенаправляя нужный поток во временный файл
    # &>  перенаправляет оба потока т.е. stdout + stderr

    #eval $CMD &> $CALC_FILE
    #echo ${DIR_CMD}/$CMD
    #exit

    #eval ${DIR_CMD}/$CMD > $CALC_FILE  2> /dev/null
    #---------------------------------
    # попробуем по другому... (заходим в папку с программой и там ее выполняем)
    (cd ${DIR_CMD} ; eval $CMD > $CALC_FILE  2> /dev/null)
    #cd $DIR_TOP #- здесь надо аккуратнее - пока не получилось!!
    #cd ..

    # --------- теперь надо сделать временные файлы с ЗАМЕНОЙ СКОБОК {}
    #CALC_FILE_SED=$CALC_FILE.sed
    #TRUE_FILE_SED=$TMP_DIR/$$.$T_FILE.true.sed

    CALC_FILE_SED=$TMP_DIR/a_CALC_SED
    TRUE_FILE_SED=$TMP_DIR/a_TRUE_SED

    #cp $CALC_FILE $CALC_FILE_SED
    #cp $TRUE_FILE $TRUE_FILE_SED

    sed -e 's/{[^ ]*}/{-----}/g' $CALC_FILE > $CALC_FILE_SED
    sed -e 's/{[^ ]*}/{-----}/g' $TRUE_FILE > $TRUE_FILE_SED

    # --ignore-all-space --ignore-blank-lines --ignore-space-change --minimal
    #diff  $TRUE_FILE $CALC_FILE  &>  $DIFF_FILE 
    #diff --ignore-all-space  $TRUE_FILE_SED  $CALC_FILE_SED  &>  $DIFF_FILE 
    diff --ignore-all-space  $TRUE_FILE_SED  $CALC_FILE_SED  1> $DIFF_FILE 2>&1 


    # $?  проверка кода возврата команды (функции, скрипта)
    if [ $? -eq 1 ]  # предыдущая команда сравнения обнаружила несовпадение
    then
      echo "" 
      echo "------------------------------------------------------DIFF-----------" 
      more $DIFF_FILE
      echo "---------------------------------------------------------------------" 
      echo "" 
      #
      # -s     подавляет эхо-вывод
      # -n N   ввод завершается автаматически после N-го символа
      # -p     задает вид строки подсказки
      #
      # read -s -n1 -p "FAILED: do you wish to overwrite (y or [n]) ? " keypress
      # но не работает на  F11 !

      echo "FAILED: do you wish to overwrite (y or [n]) ? ";
      read keypress; # а так работает и возможно надежнее "вводить и подтверждать"!

      echo; 
 
      case "$keypress" in
      "Y" | "y" )
         cp $CALC_FILE $TRUE_FILE # принимаем новый выход как истинный !
         echo "YES   : overwrite CALC -> TRUE !!"
      ;;
              * )
         echo "NOT   : continue with this CALC !"
      esac

      echo    
    else
      echo "PASSED"  # этот тест прошел
    fi

    rm $CALC_FILE  # удаляем созданный временный файл
    rm $DIFF_FILE  # 
    rm $CALC_FILE_SED
    rm $TRUE_FILE_SED
  done

}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



