;; Dynamic knowledge base implementation.
;; Interface
(defparameter *vertices* (make-hash-table :test #'equal))
(defparameter *arcs* (make-hash-table :test #'equal))
(defparameter *graphs* (make-hash-table :test #'equal))
;; SSSP
(defparameter *visited* (make-hash-table :test #'equal))
(defparameter *distances* (make-hash-table :test #'equal))
(defparameter *previous* (make-hash-table :test #'equal))
;; MinHeap
(defparameter *heaps* (make-hash-table :test #'equal))


;; -------------------------------INTERFACE--------------------------------

;; is-graph/1
;; Checks if a graph exists, returning its ID, otherwise NIL.
(defun is-graph (graph-id)
  (gethash graph-id *graphs*))

;; new-graph/1
;; Creates a new graph if it does not exist, inserting it into the hash-table.
(defun new-graph (graph-id)
  (or (gethash graph-id *graphs*)
      (setf (gethash graph-id *graphs*) graph-id)))

;; delete-graph/1
;; Removes the graph and cascades deletion of all associated vertices and arcs.
;; Keys are collected before removal to avoid mutating hash tables during iteration.
(defun delete-graph (graph-id)
  (remhash graph-id *graphs*)
  (let ((vertex-keys nil)
        (arc-keys nil))
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (and (eq (first k) 'vertex) 
                          (equal (second k) graph-id))
                 (push k vertex-keys)))
             *vertices*)
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (and (eq (first k) 'arc) 
                          (equal (second k) graph-id))
                 (push k arc-keys)))
             *arcs*)
    (mapc (lambda (k) (remhash k *vertices*)) vertex-keys)
    (mapc (lambda (k) (remhash k *arcs*)) arc-keys))
  nil)

;; new-vertex/2
;; Adds a vertex to the graph.
;; The key is in the format (vertex graph-id vertex-id).
(defun new-vertex (graph-id vertex-id)
  (setf (gethash (list 'vertex graph-id vertex-id) *vertices*)
        (list 'vertex graph-id vertex-id)))

;; graph-vertices/1
;; Returns a list containing all vertices
;; belonging to the requested graph.
(defun graph-vertices (graph-id)
  (let ((res nil))
    (maphash (lambda (k v)
               (declare (ignore k))
               (when (and (eq (first v) 'vertex) 
                          (equal (second v) graph-id))
                 (push v res)))
             *vertices*)
    res))

;; new-arc/4
;; Adds an arc between U and V with a weight (default 1).
;; Weight must be a non-negative number.
(defun new-arc (graph-id u v &optional (weight 1))
  (when (or (not (numberp weight)) (< weight 0))
    (error "new-arc: weight must be a non-negative number, got ~S" weight))
  (new-vertex graph-id u)
  (new-vertex graph-id v)
  (setf (gethash (list 'arc graph-id u v) *arcs*)
        (list 'arc graph-id u v weight)))

;; graph-arcs/1
;; Returns a list of all arcs present in a specific graph.
(defun graph-arcs (graph-id)
  (let ((res nil))
    (maphash (lambda (k v)
               (declare (ignore k))
               (when (and (eq (first v) 'arc) 
                          (equal (second v) graph-id))
                 (push v res)))
             *arcs*)
    res))

;; graph-vertex-neighbors/2
;; Returns a list containing the arcs that start
;; immediately from a given vertex.
(defun graph-vertex-neighbors (graph-id vertex-id)
  (let ((res nil))
    (maphash (lambda (k v)
               (declare (ignore k))
               (when (and (eq (first v) 'arc) 
                          (equal (second v) graph-id)
                          (equal (third v) vertex-id))
                 (push v res)))
             *arcs*)
    res))

;; graph-print/1
;; Prints to the console a list of the graph's vertices and arcs.
(defun graph-print (graph-id)
  (format t "Vertices of ~A:~%" graph-id)
  (mapc (lambda (v) (format t "  ~A~%" v)) (graph-vertices graph-id))
  (format t "Arcs of ~A:~%" graph-id)
  (mapc (lambda (a) (format t "  ~A~%" a)) (graph-arcs graph-id))
  t)


;; --------------------------------MIN_HEAP--------------------------------

;; new-heap/2
;; Initializes a new heap in the hash-table.
(defun new-heap (heap-id &optional (initial-capacity 42))
  (or (gethash heap-id *heaps*)
      (setf (gethash heap-id *heaps*)
            (list 'heap heap-id 0 (make-array initial-capacity)))))

;; heap-id/1
;; Helper: Extracts the ID from the heap representation.
(defun heap-id (h-rep) (second h-rep))

;; heap-size/1
;; Helper: Extracts the current size from the heap representation.
(defun heap-size (h-rep) (third h-rep))

;; heap-actual-heap/1
;; Helper: Extracts the physical array from the heap representation.
(defun heap-actual-heap (h-rep) (fourth h-rep))

;; heap-delete/1
;; Completely removes the heap from the global hash-table.
(defun heap-delete (heap-id)
  (remhash heap-id *heaps*)
  t)

;; heap-empty/1
;; Returns T if the heap contains no elements (size 0).
(defun heap-empty (heap-id)
  (= (heap-size (gethash heap-id *heaps*)) 0))

;; heap-not-empty/1
;; Returns T if the heap contains at least one element.
(defun heap-not-empty (heap-id)
  (> (heap-size (gethash heap-id *heaps*)) 0))

;; heap-head/1
;; Returns the list (Key Value) with the minimum key (root of the heap).
(defun heap-head (heap-id)
  (let* ((h-rep (gethash heap-id *heaps*))
         (arr (heap-actual-heap h-rep)))
    (if (> (heap-size h-rep) 0)
        (aref arr 0)
        nil)))

;; heap-swap/3
;; Swaps the position of two elements within the array.
(defun heap-swap (arr i j)
  (let ((temp (aref arr i)))
    (setf (aref arr i) (aref arr j))
    (setf (aref arr j) temp)))

;; heap-bubble-up/2
;; Orders the heap by recursively bubbling up:
;; swaps the node with parent if it is smaller.
(defun heap-bubble-up (arr i)
  (when (> i 0)
    (let* ((parent (floor (- i 1) 2))
           (k-child (first (aref arr i)))
           (k-parent (first (aref arr parent))))
      (when (< k-child k-parent)
        (heap-swap arr i parent)
        (heap-bubble-up arr parent)))))

;; heap-insert/3
;; Inserts element V with key K into the heap and restructures it (bubble-up).
(defun heap-insert (heap-id k v)
  (let* ((h-rep (gethash heap-id *heaps*))
         (size (heap-size h-rep))
         (arr (heap-actual-heap h-rep)))
    (when (>= size (length arr))
      (let ((new-arr (make-array (* 2 (length arr)))))
        (labels ((copy-arr (i)
                   (when (< i size)
                     (setf (aref new-arr i) (aref arr i))
                     (copy-arr (+ i 1)))))
          (copy-arr 0))
        (setf arr new-arr)
        (setf (fourth h-rep) new-arr)))
    (setf (aref arr size) (list k v))
    (setf (third h-rep) (+ size 1))
    (heap-bubble-up arr size)
    t))

;; heap-bubble-down/3
;; Orders the heap by recursively bubbling down: swaps the node with the minimum child.
(defun heap-bubble-down (arr i size)
  (let ((left (+ (* 2 i) 1))
        (right (+ (* 2 i) 2))
        (min-idx i))
    (when (and (< left size) 
               (< (first (aref arr left)) (first (aref arr min-idx))))
      (setf min-idx left))
    (when (and (< right size) 
               (< (first (aref arr right)) (first (aref arr min-idx))))
      (setf min-idx right))
    (when (/= min-idx i)
      (heap-swap arr i min-idx)
      (heap-bubble-down arr min-idx size))))

;; heap-extract/1
;; Removes and returns the element with the minimum key,
;; then restructures the heap (bubble-down).
(defun heap-extract (heap-id)
  (let* ((h-rep (gethash heap-id *heaps*))
         (size (heap-size h-rep))
         (arr (heap-actual-heap h-rep)))
    (if (= size 0)
        nil
        (let ((min-elem (aref arr 0)))
          (setf (aref arr 0) (aref arr (- size 1)))
          (setf (aref arr (- size 1)) nil)
          (setf (third h-rep) (- size 1))
          (heap-bubble-down arr 0 (- size 1))
          min-elem))))

;; heap-modify-key/4
;; Replaces old-key with new-key and restores heap property.
(defun heap-modify-key (heap-id new-key old-key v)
  (let* ((h-rep (gethash heap-id *heaps*))
         (size (heap-size h-rep))
         (arr (heap-actual-heap h-rep)))
    (labels ((find-idx (i)
               (if (>= i size)
                   nil
                   (let ((elem (aref arr i)))
                     (if (and (equal (first elem) old-key) 
                              (equal (second elem) v))
                         i
                         (find-idx (+ i 1)))))))
      (let ((idx (find-idx 0)))
        (when idx
          (setf (aref arr idx) (list new-key v))
          (if (and (> idx 0) 
                   (< new-key (first (aref arr (floor (- idx 1) 2)))))
              (heap-bubble-up arr idx)
              (heap-bubble-down arr idx size))
          t)))))

;; heap-print/1
;; Prints to the console the internal state of the heap array.
(defun heap-print (heap-id)
  (let* ((h-rep (gethash heap-id *heaps*))
         (size (heap-size h-rep))
         (arr (heap-actual-heap h-rep)))
    (format t "Heap ~A:~%" heap-id)
    (labels ((print-idx (i)
               (when (< i size)
                 (format t "  ~A~%" (aref arr i))
                 (print-idx (+ i 1)))))
      (print-idx 0))
    t))


;; ---------------------------------SSSP--------------------------------

;; sssp-dist/2
;; Returns the minimum calculated distance for a vertex
;; from the *distances* table.
(defun sssp-dist (graph-id vertex-id)
  (gethash (list graph-id vertex-id) *distances*))

;; sssp-visited/2
;; Returns T if the vertex has already been definitively visited by the algorithm.
(defun sssp-visited (graph-id vertex-id)
  (gethash (list graph-id vertex-id) *visited*))

;; sssp-previous/2
;; Returns the previous vertex in the shortest path to reach vertex-id.
(defun sssp-previous (graph-id vertex-id)
  (gethash (list graph-id vertex-id) *previous*))

;; sssp-change-dist/3
;; Associates the new distance to V in the hash-table *distances*.
(defun sssp-change-dist (graph-id v new-dist)
  (setf (gethash (list graph-id v) *distances*) new-dist)
  nil)

;; sssp-change-previous/3
;; Associates node U as the previous of V in the hash-table *previous*.
(defun sssp-change-previous (graph-id v u)
  (setf (gethash (list graph-id v) *previous*) u)
  nil)

;; sssp-dijkstra/2
;; Computes the shortest paths from Source to all
;; other nodes and populates the hash-tables.
(defun sssp-dijkstra (graph-id source)
  (mapc (lambda (v-rep)
          (let ((v (third v-rep)))
            (sssp-change-dist graph-id v most-positive-single-float)
            (sssp-change-previous graph-id v nil)
            (setf (gethash (list graph-id v) *visited*) nil)))
        (graph-vertices graph-id))
   
  (sssp-change-dist graph-id source 0)
  (heap-delete 'sssp-heap)
  (new-heap 'sssp-heap)
  (heap-insert 'sssp-heap 0 source)
   
  (labels ((explore ()
             (when (heap-not-empty 'sssp-heap)
               (let* ((extracted (heap-extract 'sssp-heap))
                      (u-dist (first extracted))
                      (u (second extracted)))
                 
                 (unless (sssp-visited graph-id u)
                   (setf (gethash (list graph-id u) *visited*) t)
                    
                   (let ((neighbors (graph-vertex-neighbors graph-id u)))
                     (mapc (lambda (arc)
                             (let* ((v (fourth arc))
                                    (weight (fifth arc))
                                    (v-dist (sssp-dist graph-id v))
                                    (new-d (+ u-dist weight)))
                               
                               (when (< new-d v-dist)
                                 (if (= v-dist most-positive-single-float)
                                     (heap-insert 'sssp-heap new-d v)
                                     (heap-modify-key 'sssp-heap 
                                                      new-d 
                                                      v-dist 
                                                      v))
                                 (sssp-change-dist graph-id v new-d)
                                 (sssp-change-previous graph-id v u))))
                           neighbors)))
                 (explore)))))
    (explore))
   
  (heap-delete 'sssp-heap)
  nil)

;; sssp-shortest-path/3
;; Returns the list of arcs that form the
;; shortest path from Source to V.
;; NOTE: sssp-dijkstra must be called before this function
;; to populate the distance and previous tables.
(defun sssp-shortest-path (g source v)
  (labels ((build-path (curr acc)
             (if (equal curr source)
                 acc
                 (let ((prev (sssp-previous g curr)))
                   (if prev
                       (let ((arc-weight
                              (labels ((find-weight (arcs)
                                         (cond ((null arcs) nil)
                                               ((equal (fourth (first arcs)) 
                                                       curr) 
                                                (fifth (first arcs)))
                                               (t (find-weight (rest arcs))))))
                                (find-weight (graph-vertex-neighbors g prev)))))
                         (build-path prev 
                                     (cons (list 'arc g prev curr arc-weight) 
                                           acc)))
                       nil)))))
    (build-path v nil)))
