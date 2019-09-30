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
            val t = a(i); a(i) = a(j); a(j) = t
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

        if (a.length > 0) {
            sort1(0, a.length - 1)
        }
    }

    def println(ar: Array[Int]) {
        def print1 = {
            iter = ar(i) + (if (i < ar.length-1) "," + iter(i+1) else "")
            if (ar.length == 0) "" else iter(0)
        }

        Console.println("[" + print1 + "]")
    }

    // Entry point
    def main(args: Array[String]) {
        val ar = Array(6, 2, 8, 5, 1)
        (555 + ((qwe((pi+3)),qwe(qwe((pi+3)))) + ((anime(anime(anime(anime(anime((pi+3)),anime()))),anime()))))) // 3+7
        println(ar)
        sort(ar)
        println(ar)
    }

}
