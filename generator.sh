#!/bin/bash

#todo:

# add way to generate a 'long tail' address distribution at domains (powerlaw-ish distribution)
#   and/or use real domains rather than dummy domains
# generate random user parts
# combine these two

# upload to a db table maybe


# quirks:
# domain generator will sometimes do shit like this. maybe fix later
#eanlecd.1.com
#cxag.r.com



# ======================================

function inputs() {

#inputs can include:
# -n - number of total records to generate (required)
# -d - number of unique domains to generate (optional).
#	if not specified, created based on # of records in file
# -v - verbose mode


if [[ ! "$@" ]]; then
  echo "error: no input defined"
  return 1
fi


while [[ "$1" ]] ; do

  case "$1" in

    -n )
	shift
	num_records="$1"
	;;

    -d )
	shift
	num_domains="$1"
	;;

    "-v" )
	#set verbose mode on
	gen_verbose=1
	;;

    * )
	echo "error: input not recognized"
	exit 0
  esac

  shift
done



} #end function inputs


# ======================================

function validate_inputs() {

if [[ ! "$num_records" ]]; then
  echo "error: missing input for number of records to generate"
  return 1
fi

###todo:
#make sure num_records and num_domains are positive integers



} # end function validate_inputs


# ======================================


function calculate_defult_num_domains() {

#should always be set but just in case
if [[ ! "$num_records" ]]; then
  echo "error: records variable not set; exiting"
  return 1
fi

#formula:
# domains = 5^(log10(num_records))
# so records	domains
# 10	5
# 100	25
# 1k	125

#just skip calculation if records < 10
if [[ $num_records -lt 10 ]]; then
  case $num_records in

  9 | 8 | 7 )	num_domains=3	;;
  6 | 5 | 4 )	num_domains=2	;;
  3 | 2 | 1 )	num_domains=1	;;

  * )	#that would be odd
	num_domains=1
  esac
  return 0
fi

#otherwise, do calculation

local log_records=$( echo "scale=3; l($num_records) / l(10)" | bc -l)
if [ $? -gt 0 ]; then
  echo "error calculating log"
fi

#bc will only do exponents for whole numbers, so trim decimals
local log_records_int=$(echo "$log_records" | cut -d\. -f1)
local log_records_dec=$(echo "$log_records" | cut -d\. -f2)

local domains_tmp=$(echo "5 ^ $log_records_int" | bc )

#then do half-assed math to scale this a little
local mult="1.$log_records_dec"

#quirk with bc means multiplication doesn't get 'scale' applied; so we have to divide by 1
num_domains=$(echo "scale=0; ($domains_tmp * $mult)/1" | bc)


if [[ $gen_verbose -gt 1 ]]; then
  echo "log: $log_records"
  echo "int: $log_records_int"
  echo "mult: $mult"
  echo "calculated domains: $num_domains"
fi


} #end function calculate_defult_num_domains


# ======================================

function generate_domains () {
# generates our list of domains & adds to domains array

#global $domains array:
declare -a domains

#check required var first
if [[ ! "$num_domains" ]]; then
  echo "error: num_domains variable not set"
  return 1
fi

if [[ $verbose -gt 0 ]]; then
  echo -n "Generating domains..."
fi

for (( i=0; i < $num_domains; i++ )); do

#length should vary between 3 characters and ~ 30, with average length of 10-ish
#this gives a roughly gaussian-ish distribution
local length=$(( ((RANDOM / 5 ) + RANDOM + RANDOM + RANDOM) / 4792 ))

local mod1=$(( RANDOM % 11 ))
if [[ $mod1 -eq 0 ]]; then
  #in a small pct of cases, add more (to generate a longer 'tail' / make the distribution a bit more poisson-like)
  local add_length=$(( RANDOM / 4841 ))
  local length=$(( length + add_length ))
fi

#set some bounds on this
if [[ "$length" -lt 3 ]]; then
  local length=3
elif [[ "$length" -gt 50 ]]; then
  local length=50
fi

#for debugging:
#echo "$length" >> length_test

local dom_rand_tmp=$( < /dev/urandom tr -dc a-z0-9.- | head -c${1:-$length}; echo )

#clean up some common formatting issues:
# - should start and end with alphanum (no dots or dashes)
# - should not have two consecutive dots or dashes
# - should not have -. or .-
local dom_rand=$(echo "$dom_rand_tmp" | sed "s/^-*//g;s/^\.*//g;s/-*$//g;s/\.*$//g" | \
  sed "s/--/-/g;s/\.\././g" | \
  sed "s/-\.//g;s/\.-//g" )

#debug
#echo "rand: $dom_rand	orig: $dom_rand_tmp"

#test length again here (against alphanum only)
local new_length=$(echo "$dom_rand" | tr -dc a-z0-9 | wc -c)
if [[ $new_length -lt 3 ]]; then
  #skip adding to array; repeat loop iteration
  let i--
  continue
  sleep 1
fi

#otherwise, add to array
domains+=("${dom_rand}.com")


### change based on # we're generating?
if [[ $verbose -gt 0 ]]; then
  local mod2=$(( i % 100 ))
  if [[ $mod2 -eq 0 && $i -gt 0 ]]; then
     sleep 1
     echo -n "."
  fi
fi

done

if [[ $verbose -gt 0 ]]; then echo ""; fi


#debug
#printf -- '%s\n' "${domains[@]}"

#convert from array to lines of txt
generated_domains=$(printf -- '%s\n' "${domains[@]}")


#local dat_tmp=$(date '+%Y-%m-%d')
#echo x > "generated_list_${dat_tmp}.txt"
#echo ""
#echo "domains in generated_list_${dat_tmp}.txt"
#echo ""


} #end function generate_domains


# ======================================


function genrate_emails() {

#decent looking decay function is something like this:

#=0.3^(1/$prev_rank)
# where prev_rank starts at 1

### we could also do some random variation on this too - gaussian distribution perhaps

# but that just gives us raw numbers with a first number input
# and we want percentages of the list instead
# so we'll have to massage it a bit more


: #


}


# ======================================



function main() {

#set defaults
gen_verbose=0


#parse inputs
inputs "$@"
if [ $? -gt 0 ]; then
  exit 1
fi

validate_inputs
if [ $? -gt 0 ]; then
  exit 1
fi

if [[ ! "$num_domains" ]]; then
  calculate_defult_num_domains
fi

if [[ $gen_verbose -gt 0 ]]; then
  echo "Creating $num_records addresses at $num_domains different domains"
fi

generate_domains


}
main "$@"
