package examples

/** Quick sort, impe*rat/ive style */

object sort {

    /** Nested methods can use and even update everything
    *  visible in their scope (including local variables or
    *  arguments of enclosing methods).
    */
    
    def qwe() {
        def qwe1 {
            def qwe2() {
                def qwe3 {
                
                }
            }
        }
    }
    
    // Entry point
    def main(args: Array[String]) {

        var i = Console.readInt().negative()
        var x = 1
        var y = 10
        val a:Int = Console.readInt()
        val b:Int = -2
        val c:Int = 20 + x - a / y * i
        var d:String
        var e:String = ""
        var f:String = e
        
        /*
        i match {
            case 1 => {
                Console.println("Winter")
            }
            case 2 => {
                Console.println("Spring")
            }
            case 3 => {
                Console.println("Summer")
            }
            case 4 => {
                Console.println("Autumn")
            }
            case 5 => {
                Console.println("Autumn")
            }
            case _ => {
                Console.println("Invalid Season")
            }
        }
        
        x==5 ? Console.println("x == 5") : Console.println("x != 5")

        while (y <= 100){
            while (x < 100){
                  x += 1
            }
            y += 1
        }
              
        if (y == 3) {
            Console.println("y equals to 3")
            if (x > 3) {
                Console.println("x is greater than 3")
            } else {
                Console.println("x is lower or equals to 3")
            }
        }
        */

    }

}
