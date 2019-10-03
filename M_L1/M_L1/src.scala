
package examples

/** Quick sort, impe*rat/ive style */

object sort {

/** Nested methods can use and even update everything
*  visible in their scope (including local variables or
*  arguments of enclosing methods).
*/


def sort(a: Array[Int]) {
/*ANIME-STAR*/
def swap(i: Int, j: Int) {
val t = a(i)
a(i) = a(j)
a(j) = t
}


def sort1(l: Int, r: Int) {
val pivot = a((l + r) / 2)
var i = l
var j = r

while (i <= j) {
while (a(i) < pivot) i += 1
while (a(j) > pivot) j -= 1

if (i <= j) {
swap(i, j)
i += 1
j -= 1
}
}

if (l < j) {
sort1(l, j)
}

if (j < r) {
sort1(i, r)
}

}

if (a.length() > 0) {
sort1(0, a.length() - 1)
}

}


def println(ar: Array[Int]) {
def print1 = {
iter() = ar(i) + (if (i < ar.length()-1) "," + iter(i+1) else "")
if (ar.length() == 0) "" else iter(0)
}

Console.println("[" + print1() + "]")
}


def squareEquasion(a:Int,b:Int,c:Int) {
val d = b*b-4*a*c
val di = sqrt(d)
val x1 = (-b + di)/(2*a)
val x2 = (-b - di)/(2*a)

x0 = -c/b
if(a==0&&b<0){
Console.println("-inf to " + x0)
} else
if(a==0&&b>0){
Console.println(x0 + " to +inf")
} else
if(d>0&&a>0){
Console.println(x1 + " to " + x2)
} else
if(d>0&&a>0){
Console.println(x2 + " to " + x1)
} else
if(d>0&&a<0){
Console.println("-inf to " + x1 + ", " + x2 + " to +inf" )
} else
if(d<=0&&a>0){
Console.println("No solution")
} else
if(d==0&&a<0){
Console.println("All except " + x1)
} else
if(d<0&&a<0){
printf("-inf to +inf")
}

}


def myArr() {
val n = 10
var counter = 0
var i = 0
var num = 0

var min = 0
val a = Array(1, 7, 14, 8, 9, 4, 7, 2, 4, 0)
var sum=0
var m = 0

for( i <- 0 to n-1 ){
if(a(i)==0){
counter += 1
}

}

min = arr(0)

for(i <- 0 to n-1){
if(min>a(i)){
min = a(i)
num = i
}
}

for(i <- 0 to n-1){
if (i>num){
sum+=a(i)
}
}

val b = Array(2, 5, 6, 3, 4, 1, 4, 5, 6, 7)

for (i <- 0 to n-1){
for (j <- n-1 to i by -1){
if(a(j-1)>a(j)){
m = a(j-1)
a(j-1) = a(j)
a(j) = m
}
}
}

min=a(0)
for (i <- 0 to n-1){
for (j <- 0 to n-1){
if (a(i)==b(j)){
min = a(i+1)
}
}
}
}


def lab(){

}

def lab1(){
    print((abc),)
}


// Entry point
def main(args: Array[String]) {
val ar = Array(6, 2, 8, 5, 1)
println(ar)
sort(ar)
println(ar)

squareEquasion(5, 10, 4)
myArray()
anime(star)
}

}

