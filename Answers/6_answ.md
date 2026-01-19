# Понятие критической области

Понятие критической области - продолжи ... 

---

## Вопрос 20: Взаимоисключение с активным ожиданием

### Определение критической области

**Критическая область (Critical Section)** - это участок кода программы, в котором процесс или поток получает доступ и может изменять данные, общие с другими процессами или потоками.

### Проблема race condition

При одновременном доступе к общим данным нескольких процессов может возникнуть **race condition** (условие гонки). Это ситуация, когда несколько процессов одновременно обращаются к одним и тем же данным, и финальный результат зависит от порядка выполнения операций.

**Пример:**
```
Два потока инкрементируют переменную count:
Поток 1: register1 = count;      // register1 = 5
         register1 = register1 + 1;  // register1 = 6
         count = register1;       // count = 6

Поток 2: register2 = count;      // register2 = 5
         register2 = register2 - 1;  // register2 = 4
         count = register2;       // count = 4
```

При чередовании операций результат может быть неправильным (4 или 6 вместо 5).

### Требования к решению проблемы критической области

Решение должно удовлетворять трем требованиям:

1. **Взаимоисключение (Mutual Exclusion)** - если один процесс находится в критической области, ни один другой процесс не может находиться в своей критической области одновременно.

2. **Прогресс (Progress)** - если ни один процесс не находится в критической области и есть процессы, желающие войти, то только эти процессы могут определить, кто войдет первым, и решение не может откладываться бесконечно.

3. **Ограниченное ожидание (Bounded Waiting)** - существует граница на количество раз, когда другие процессы могут войти в критическую область, прежде чем процесс, запросивший вход, получит право входа.

### Взаимоисключение с активным ожиданием

**Активное ожидание (Busy Waiting)** - это метод синхронизации, когда процесс непрерывно проверяет условие в цикле, ожидая возможности входа в критическую область.

**Схема работы:**
```
while true:
    ENTRY SECTION:
        // Активно ждем возможности входа
        while (условие_не_выполнено):
            // Пустой цикл - пусто жидания
            continue
    
    CRITICAL SECTION:
        // Работа с общими данными
        
    EXIT SECTION:
        // Изменяем условие для других процессов
```

### Недостатки активного ожидания

- **Неэффективность**: CPU впустую выполняет циклы ожидания, что вызывает излишнее потребление вычислительных ресурсов.
- **Невозможность использования на одноядерных системах**: один процесс, занимающий CPU в цикле ожидания, не позволяет другим процессам выполняться.
- **Плохая масштабируемость**: на многопроцессорных системах множество процессов могут конкурировать за ресурс.

### Преимущества активного ожидания

- **На многоядерных системах**: когда блокировка удерживается короткое время, активное ожидание быстрее, чем переключение контекста (context switch требует 2 переключений).
- **Простота реализации**: не требует системных вызовов и усложненных структур данных.
- **Используется в spinlock'ах** на современных многопроцессорных системах для коротких критических областей.

---

## Вопрос 21: Взаимоисключение с активным ожиданием.

### Аппаратное обеспечение для синхронизации

#### Память Barriers (Барьеры памяти)

**Memory Barrier** - команда процессора, которая гарантирует, что все операции загрузки и сохранения в памяти завершены перед выполнением последующих операций.

**Проблема без barrier:**
Процессор может переупорядочить инструкции для оптимизации. Например:
```c
flag = false;
int x = 0;

// Поток 1:
while (!flag) 
    memory_barrier();  // Гарантирует загрузку flag
print(x);

// Поток 2:
x = 100;
memory_barrier();      // Гарантирует сохранение x
flag = true;
```

#### Аппаратные инструкции

**Test-and-Set (TSL)**
```c
atomic boolean test_and_set(boolean *target) {
    boolean rv = *target;
    *target = true;
    return rv;
}
```

**Compare-and-Swap (CAS)**
```c
atomic int compare_and_swap(int *value, int expected, int new_value) {
    int temp = *value;
    if (*value == expected)
        *value = new_value;
    return temp;
}
```

### Спин-мьютекс (Spinlock)

**Спин-мьютекс** - мьютекс, использующий активное ожидание через CAS.

**Реализация:**
```c
struct SpinMutex {
    volatile bool flag;
};

void lock_spinmutex(SpinMutex *spin) {
    while (true) {
        // CAS инструкция: сравни флаг с 0, установи в 1
        if (compare_and_swap(&spin->flag, 0, 1) == 0) {
            // Успешно захватили
            break;
        }
        // Инструкция PAUSE для снижения потребления энергии
        pause();
    }
}

void unlock_spinmutex(SpinMutex *spin) {
    spin->flag = false;
}
```

**Когда использовать:**
- На многоядерных системах
- Когда критическая область занимает меньше двух переключений контекста (~несколько микросекунд)
- Для коротких критических областей ядра ОС

---

## Вопрос 22: Алгоритм Петерсона (мьютекс на N потоков)

### Алгоритм Петерсона для двух процессов

**История**: Разработан Гэри Петерсоном в 1981 году как классическое решение проблемы критической области.

### Структура данных

```c
int turn = 0;           // Чей ход: 0 или 1
boolean flag[2] = {false, false};  // Готовы ли процессы войти
```

### Алгоритм для процесса Pi (i = 0 или 1)

```c
while (true) {
    // ENTRY SECTION
    flag[i] = true;
    turn = j;  // где j = 1-i (другой процесс)
    while (flag[j] && turn == j) {
        // Активное ожидание
    }
    
    // CRITICAL SECTION
    // ... критическая область ...
    
    // EXIT SECTION
    flag[i] = false;
    
    // REMAINDER SECTION
}
```

### Доказательство корректности

**1. Взаимоисключение:**
- Процесс Pi входит в критическую область только если: `flag[j] == false` ИЛИ `turn == i`
- Если оба процесса могут быть одновременно в критической области, то оба должны иметь `flag[0] == true` И `flag[1] == true`
- Но `turn` может быть только 0 или 1, не оба одновременно
- Один процесс будет успешно пройден цикл while, другой - нет

**2. Прогресс:**
- Pi может застрять только в while цикле с условием: `flag[j] == true && turn == j`
- Если Pj не готов (`flag[j] == false`), Pi входит
- Если Pj готов и выполняет while, то либо `turn == i` (Pi входит), либо `turn == j` (Pj входит)
- Когда Pj выходит, устанавливает `flag[j] = false`, позволяя Pi войти

**3. Ограниченное ожидание:**
- Когда Pj выходит из критической области, оно устанавливает `flag[j] = false`
- Если Pj снова хочет войти, оно установит `turn = i`
- Так как Pi не изменяет turn в цикле ожидания, Pi войдет в течение одного цикла Pj

### Проблемы на современных архитектурах

**Переупорядочение инструкций:**

```
Process P0:
flag[0] = true;    // может быть выполнено позже
turn = 1;

Process P1:
flag[1] = true;    // может быть выполнено позже
turn = 0;
```

Если инструкции переупорядочены, оба процесса могут одновременно войти в критическую область!

**Решение**: Использовать memory barriers:
```c
flag[i] = true;
memory_barrier();  // Гарантирует видимость flag перед выполнением turn
turn = j;
```

### Расширение на N процессов

**Алгоритм Петерсона может быть рекурсивно расширен на N процессов:**

```c
struct Peterson_Lock {
    int flag[N];
    int victim[N];  // На каком уровне рекурсии
};

// Базовый случай (N=2): стандартный алгоритм Петерсона

// Для N процессов используется N-1 уровней блокировки:
// На уровне k процесс пытается пройти через k-th мьютекс
// Если процесс i входит в уровень k после процесса j,
// то victim[k] = i, давая преимущество j
```

**Сложность**: O(N²) операций в худшем случае для входа в критическую область.

---

## Вопрос 23: Приостановка и активизация. Семафор, мьютекс и условная переменная

### Проблемы с активным ожиданием

- Впустую тратится CPU время
- На одноядерных системах невозможна работа других процессов
- Низкая эффективность на высоконагруженных системах

### Решение: Приостановка и Активизация

**Идея**: Процесс, не имеющий доступа к ресурсу, должен быть приостановлен (заснуть), а не крутиться в цикле.

**Примитивы:**
- **sleep()** - приостановить процесс, отправить его в очередь ожидания
- **wakeup(process)** - разбудить процесс, переместить из очереди ожидания в очередь готовых

### Семафор (Semaphore)

**Определение**: Целочисленная переменная, доступная только через две атомарные операции: `wait()` (P-операция) и `signal()` (V-операция).

**Структура:**
```c
typedef struct {
    int value;              // Счетчик
    struct process_list list;  // Список ожидающих процессов
} semaphore;
```

**Операции:**

```c
void wait(semaphore S) {
    S->value--;
    if (S->value < 0) {
        // Добавить текущий процесс в S->list
        sleep();  // Процесс засыпает
    }
}

void signal(semaphore S) {
    S->value++;
    if (S->value <= 0) {
        // Удалить процесс P из S->list
        wakeup(P);  // Разбудить процесс
    }
}
```

**Типы семафоров:**

1. **Двоичный семафор** (Binary Semaphore): значение только 0 или 1
   - Используется для взаимоисключения
   ```c
   semaphore mutex = 1;
   wait(mutex);        // Enter CS
   // critical section
   signal(mutex);      // Exit CS
   ```

2. **Счетный семафор** (Counting Semaphore): значение >= 0
   - Используется для управления доступом к N ресурсам
   ```c
   semaphore resources = N;
   // Каждый процесс перед использованием ресурса:
   wait(resources);
   // use resource
   signal(resources);
   ```

**Применение для синхронизации:**
```c
// Два процесса P1 и P2
// Требование: S2 выполняется только после S1

semaphore synch = 0;

// P1:
S1;
signal(synch);

// P2:
wait(synch);
S2;
```

### Мьютекс (Mutex Lock)

**Определение**: Взаимное исключение - примитив синхронизации с двумя операциями: `acquire()` и `release()`.

**Структура:**
```c
typedef struct {
    boolean available;  // true = свободен, false = занят
} mutex_lock;
```

**Операции:**

```c
void acquire(mutex_lock lock) {
    while (!lock->available) {
        // Активное ожидание (спин)
    }
    lock->available = false;
}

void release(mutex_lock lock) {
    lock->available = true;
}
```

**Использование:**
```c
while (true) {
    acquire(lock);
    // CRITICAL SECTION
    release(lock);
    // REMAINDER SECTION
}
```

**Различия от семафора:**
- Мьютекс проще (да/нет вместо счетчика)
- Мьютекс явно разработан для взаимоисключения
- Семафор более универсален

### Условная переменная (Condition Variable)

**Определение**: Механизм синхронизации, который позволяет потокам ждать, пока определенное условие не станет истинным.

**Структура:**
```c
typedef struct {
    // Внутренний счетчик и список ожидающих
} condition_variable;
```

**Операции:**

```c
void wait(condition_variable cv, mutex_lock lock) {
    // Атомарно:
    // 1. Отпустить lock
    // 2. Добавить текущий процесс в список ожидания cv
    // 3. Заснуть
    // 4. (При пробуждении) Снова захватить lock
}

void signal(condition_variable cv) {
    // Пробудить ОДИН процесс из списка ожидания cv
    // Процесс просыпается в wait() после переосвоения lock
}

void broadcast(condition_variable cv) {
    // Пробудить ВСЕ процессы из списка ожидания cv
}
```

**Использование - Bounded Buffer:**
```c
typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t not_full;   // Буфер не полон
    pthread_cond_t not_empty;  // Буфер не пуст
    int buffer[SIZE];
    int count = 0;
} bounded_buffer;

void insert(bounded_buffer *buf, int value) {
    pthread_mutex_lock(&buf->mutex);
    
    // Ждем, пока буфер не будет полон
    while (buf->count == SIZE) {
        pthread_cond_wait(&buf->not_full, &buf->mutex);
    }
    
    buf->buffer[buf->count++] = value;
    
    // Пробуждаем потребителей
    pthread_cond_signal(&buf->not_empty);
    
    pthread_mutex_unlock(&buf->mutex);
}

void remove(bounded_buffer *buf, int *value) {
    pthread_mutex_lock(&buf->mutex);
    
    // Ждем, пока буфер не будет пуст
    while (buf->count == 0) {
        pthread_cond_wait(&buf->not_empty, &buf->mutex);
    }
    
    *value = buf->buffer[--buf->count];
    
    // Пробуждаем производителей
    pthread_cond_signal(&buf->not_full);
    
    pthread_mutex_unlock(&buf->mutex);
}
```

### Сравнение трех механизмов

| Характеристика | Семафор | Мьютекс | Условная переменная |
|---|---|---|---|
| **Тип значения** | Целое число (0+) | Булевый флаг | Очередь ожидания |
| **Предназначение** | Универсальная синхронизация | Взаимоисключение | Синхронизация условий |
| **Использует блокировку** | Нет/Да (в реализации) | Да | Да (требует мьютекса) |
| **Binary/Counting** | Оба типа | Только двоичный | - |
| **Освобождение** | Любой процесс | Владелец | Явный вызов signal |
| **Сложность** | Средняя | Низкая | Высокая |
| **Масштабируемость** | Хорошо | Очень хорошо | Зависит от реализации |

---

## Вопрос 24: Приостановка и активизация. Отличия условной переменной от семафора

### Основные отличия

#### 1. **Семантика ожидания**

**Семафор:**
- Может использоваться без явного условия
- `wait()` просто уменьшает счетчик
- Запомненное значение: если `signal()` был вызван до `wait()`, счетчик будет положительным

```c
semaphore sem = 0;

// Процесс 1:
signal(sem);    // sem = 1

// Позже Процесс 2:
wait(sem);      // sem = 0, не блокируется (работает!)
```

**Условная переменная:**
- Всегда используется с мьютексом
- `wait()` блокируется только если условие не истинно
- НЕ запоминает сигналы: если `signal()` вызван до `wait()`, он потеряется

```c
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// Процесс 1:
pthread_mutex_lock(&mutex);
pthread_cond_signal(&cond);    // Сигнал, но никто не слушает
pthread_mutex_unlock(&mutex);

// Позже Процесс 2:
pthread_mutex_lock(&mutex);
// Сигнал уже потеряется!
pthread_cond_wait(&cond, &mutex);  // Будет блокирован!
pthread_mutex_unlock(&mutex);
```

#### 2. **Атомарность**

**Семафор:**
- `wait()` и `signal()` атомарны сами по себе
- Не требует явной блокировки

**Условная переменная:**
- `wait()` требует мьютекса
- Мьютекс отпускается АТОМАРНО с засыпанием процесса
- Это гарантирует, что сигнал не будет потерян между проверкой условия и засыпанием

```c
// Неправильно (может произойти race condition):
if (condition_not_met) {
    // Другой поток может здесь изменить условие и вызвать signal()
    pthread_cond_wait(&cond, &mutex);
}

// Правильно:
while (condition_not_met) {  // while, не if!
    pthread_cond_wait(&cond, &mutex);  // Освобождает и захватывает атомарно
}
```

#### 3. **Пробуждение**

**Семафор:**
- `signal()` пробуждает ОДИН процесс в строгом FIFO порядке
- Гарантия: процессы просыпаются в порядке, в котором они уснули

**Условная переменная:**
- `signal()` пробуждает ОДИН произвольный процесс (в зависимости от реализации)
- `broadcast()` пробуждает ВСЕ процессы (thundering herd problem)
- Нет гарантии FIFO порядка

#### 4. **Использование мьютекса**

**Семафор:**
- Может использоваться самостоятельно для взаимоисключения
- Двоичный семафор = мьютекс
- Счетный семафор = контроль доступа к N ресурсам

**Условная переменная:**
- ВСЕГДА используется с мьютексом
- Не может использоваться самостоятельно
- Мьютекс обеспечивает взаимоисключение для проверки условия

#### 5. **Сигнал перед ожиданием**

**Семафор - работает:**
```c
semaphore sem = 0;

// Thread 1:
signal(sem);     // sem.value = 1

// Thread 2:
wait(sem);       // sem.value = 0, НЕ блокируется
```

**Условная переменная - НЕ работает:**
```c
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

// Thread 1:
pthread_cond_signal(&cond);  // Сигнал потеряется!

// Thread 2:
pthread_cond_wait(&cond, &mutex);  // Будет БЛОКИРОВАН навсегда!
```

### Рекомендации по использованию

| Ситуация | Используйте |
|---|---|
| Взаимоисключение простое | Мьютекс |
| Контроль доступа к N ресурсам | Счетный семафор |
| Синхронизация двух событий | Двоичный семафор |
| Ожидание сложного условия | Условная переменная |
| Производитель-Потребитель | Условная переменная (с 2 CV) |
| Читатели-Писатели | Условная переменная или семафоры |

### Пример: Производитель-Потребитель

**С семафорами:**
```c
semaphore empty = BUFFER_SIZE;
semaphore full = 0;
semaphore mutex = 1;

// Производитель:
while (true) {
    item = produce();
    wait(empty);        // Ждем пустого слота
    wait(mutex);
    buffer[in] = item;
    in = (in + 1) % SIZE;
    signal(mutex);
    signal(full);       // Сообщаем потребителю
}

// Потребитель:
while (true) {
    wait(full);         // Ждем полного слота
    wait(mutex);
    item = buffer[out];
    out = (out + 1) % SIZE;
    signal(mutex);
    signal(empty);      // Сообщаем производителю
    consume(item);
}
```

**С условными переменными:**
```c
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t not_empty = PTHREAD_COND_INITIALIZER;
pthread_cond_t not_full = PTHREAD_COND_INITIALIZER;
int count = 0;

// Производитель:
void *producer(void *arg) {
    while (true) {
        item = produce();
        pthread_mutex_lock(&mutex);
        while (count == BUFFER_SIZE) {  // Ждем, пока буфер не опустеет
            pthread_cond_wait(&not_full, &mutex);
        }
        buffer[in] = item;
        in = (in + 1) % SIZE;
        count++;
        pthread_cond_signal(&not_empty);  // Уведомляем потребителя
        pthread_mutex_unlock(&mutex);
    }
}

// Потребитель:
void *consumer(void *arg) {
    while (true) {
        pthread_mutex_lock(&mutex);
        while (count == 0) {  // Ждем, пока буфер не заполнится
            pthread_cond_wait(&not_empty, &mutex);
        }
        item = buffer[out];
        out = (out + 1) % SIZE;
        count--;
        pthread_cond_signal(&not_full);   // Уведомляем производителя
        pthread_mutex_unlock(&mutex);
        consume(item);
    }
}
```

---

## Вопрос 25: Атомарные переменные (атомики). CAS инструкция. Спин-мьютекс

### Атомарные переменные (Atomic Variables)

**Определение**: Переменная, все операции с которой выполняются атомарно (неделимо), без возможности прерывания и чередования другими потоками.

### Проблема обычных переменных

```c
volatile int x = 0;

// Компилируется в:
// mov eax, DWORD PTR x    // Загрузить
// inc eax                 // Инкрементировать
// mov DWORD PTR x, eax    // Сохранить
```

**Race condition:**
```
Поток 1:        Поток 2:
mov eax, [x]    // eax = 0
                mov ebx, [x]    // ebx = 0
inc eax         // eax = 1
                inc ebx         // ebx = 1
mov [x], eax    // x = 1
                mov [x], ebx    // x = 1 (вместо 2!)
```

### Compare-and-Swap (CAS) инструкция

**Определение**: Аппаратная инструкция, которая атомарно:
1. Сравнивает значение переменной с ожидаемым значением
2. Если совпадает - устанавливает новое значение
3. Возвращает старое значение

**Псевдокод:**
```c
int compare_and_swap(int *ptr, int expected, int new_value) {
    int temp = *ptr;
    if (*ptr == expected)
        *ptr = new_value;
    return temp;
}
```

**x86-64 инструкция:**
```nasm
lock cmpxchg destination, source
; prefix LOCK гарантирует атомарность
; Сравнивает RAX с destination, если равны - загружает source в destination
```

**Пример использования для инкрементирования:**
```c
void increment_atomic(atomic_int *x) {
    int temp;
    do {
        temp = x->value;  // Загрузить текущее значение
    } while (compare_and_swap(&x->value, temp, temp + 1) != temp);
    // Повторять до успеха (пока никто не изменил значение между проверкой и CAS)
}
```

**Преимущества CAS над блокировками:**
- Нет блокировок → нет deadlock
- На невысоконагруженных системах: быстрее чем блокировки
- Оптимистичный подход: предполагаем успех, затем проверяем конфликты

### Спин-мьютекс (Spinlock) на основе CAS

**Структура:**
```c
struct SpinMutex {
    volatile int flag;  // 0 = свободен, 1 = занят
};
```

**Реализация на C с CAS:**
```c
void lock_spinmutex(struct SpinMutex *spin) {
    while (compare_and_swap(&spin->flag, 0, 1) != 0) {
        // CAS вернул 1, значит мьютекс занят
        // Повторяем попытку
        pause();  // x86 инструкция для снижения энергопотребления
    }
}

void unlock_spinmutex(struct SpinMutex *spin) {
    spin->flag = 0;  // Отпустить мьютекс
}
```

**x86-64 ассемблер:**
```nasm
lock_spinmutex:
    mov al, 0      ; expected value
    mov bl, 1      ; new value
.trylock:
    lock cmpxchg [rdi], bl  ; попытка CAS
    je .acquired           ; если успешно - выходим
    pause                  ; если нет - pause инструкция
    jmp .trylock           ; повторяем

.acquired:
    ret

unlock_spinmutex:
    mov DWORD PTR [rdi], 0  ; flag = 0
    ret
```

**Реализация на Java:**
```java
import java.util.concurrent.atomic.AtomicInteger;

public class SpinMutex {
    private AtomicInteger flag = new AtomicInteger(0);
    
    public void lock() {
        while (flag.compareAndSet(0, 1)) {
            // Пока CAS не вернет true (успешное изменение с 0 на 1)
            Thread.onSpinWait();  // Java 9+: аналог PAUSE
        }
    }
    
    public void unlock() {
        flag.set(0);
    }
}
```

### Характеристики Спин-мьютекса

| Характеристика | Значение |
|---|---|
| **Тип ожидания** | Активное (busy-waiting) |
| **Context switch** | Не требует |
| **Эффективность** | Коротко < 2µs (длительность context switch) |
| **Использование** | Многоядерные системы, короткие CS |
| **На одноядерных** | Неэффективен (бесполезное вращение) |
| **На высоконагруженных** | Неэффективен (CPU тратится впустую) |

### Когда использовать Spinlock

**Используйте когда:**
- Многоядерная система (несколько независимых ядер)
- Критическая область очень короткая (< 2 микросекунды)
- Мьютекс редко будет конфликтной (low contention)
- ОС ядро (где context switch дорогой)

**НЕ используйте когда:**
- Одноядерная система
- Критическая область длинная (> 10 микросекунд)
- Высокая конфликтность (много потоков конкурируют)
- Приложение пользователя (context switch дешевле)

### Атомарные операции в разных языках

**C11 / C++11:**
```c
#include <stdatomic.h>

atomic_int x = ATOMIC_VAR_INIT(0);

atomic_fetch_add(&x, 1);  // Атомарный инкремент
atomic_compare_exchange_strong(&x, &expected, new);
```

**C++ (STL):**
```cpp
#include <atomic>

std::atomic<int> x(0);

x.fetch_add(1, std::memory_order_seq_cst);  // Атомарный инкремент
x.compare_exchange_strong(expected, new);
```

**Java:**
```java
import java.util.concurrent.atomic.*;

AtomicInteger x = new AtomicInteger(0);
x.getAndIncrement();  // Атомарный инкремент
x.compareAndSet(expected, new);
```

**Linux (GCC built-in):**
```c
int sync_fetch_and_add(int *ptr, int value);
bool __sync_bool_compare_and_swap(int *ptr, int old, int new);
```

### Производительность: Семафор vs Спин-мьютекс vs Мьютекс

```
На многоядерной системе:
- Невысокая конфликтность (< 5%):
  Спин-мьютекс > Мьютекс > Семафор

- Средняя конфликтность (5-50%):
  Мьютекс ≈ Спин-мьютекс > Семафор

- Высокая конфликтность (> 50%):
  Мьютекс > Семафор > Спин-мьютекс
```

---

## Вопрос 26: Передача сообщений. Барьеры

### Передача сообщений (Message Passing)

**Определение**: Механизм синхронизации и взаимодействия процессов, при котором процессы обмениваются данными через явный обмен сообщениями, а не через общую память.

**Отличие от shared memory:**

```c
// SHARED MEMORY синхронизация:
shared_data = value;  // Прямой доступ
mutex.lock();
shared_data += 1;
mutex.unlock();

// MESSAGE PASSING синхронизация:
message_t msg = {data: value};
send(process_id, msg);  // Отправка сообщения
receive(source, &msg);  // Получение сообщения
```

### Основные операции

**Send операция:**
```c
send(destination_id, message)
// Отправляет сообщение к процессу destination_id
// Может быть:
// - Синхронная (блокирующая): ждет пока получатель примет
// - Асинхронная: сразу возвращается, сообщение в буфере
```

**Receive операция:**
```c
receive(source_id, &message)
// Получает сообщение от процесса source_id
// Может быть:
// - Синхронная (блокирующая): ждет сообщения
// - Асинхронная: возвращает ошибку если нет сообщений
// - С timeout: ждет указанное время
```

### Типы каналов передачи сообщений

#### 1. **Direct Communication**
```c
// Процесс явно указывает отправителя/получателя
send(destination, message);
receive(source, &message);

// Пример: Процесс 0 отправляет процессу 1
// Процесс 0:
send(1, "Hello");

// Процесс 1:
receive(0, &msg);  // Ждет сообщения именно от процесса 0
```

#### 2. **Indirect Communication** (через почтовый ящик)
```c
// Сообщения отправляются в очередь (почтовый ящик)
send(mailbox, message);
receive(mailbox, &message);

// Несколько процессов могут читать из одного почтового ящика
mailbox_t inbox = create_mailbox();

// Процесс 1:
send(inbox, "Message 1");

// Процесс 2:
send(inbox, "Message 2");

// Процесс 3:
receive(inbox, &msg);  // Может получить Message 1 или 2
receive(inbox, &msg);  // Получит второе сообщение
```

### Буферизация сообщений

**0-Capacity Buffer (синхронная передача):**
```
send() блокируется до вызова receive()
receive() блокируется до вызова send()

Процесс 1:        Процесс 2:
send(msg)         
  (ждет)          
                  receive(&msg)  // send() возвращается
```

**Bounded-Capacity Buffer:**
```
send() блокируется если буфер полон
Очередь хранит до N сообщений

Процесс 1:        Процесс 2:
send(msg1)        
send(msg2)        receive(&msg1)
send(msg3)        receive(&msg2)
send(msg4)        receive(&msg3)
  (ждет)          
                  receive(&msg4)  // send() возвращается
```

**Unbounded-Capacity Buffer:**
```
send() никогда не блокируется
Может использовать бесконечно памяти (проблема!)

Процесс 1:        Процесс 2:
send(msg1)        
send(msg2)        
send(msg3)        
  (возвращается)  
                  receive(&msg1)
                  receive(&msg2)
                  receive(&msg3)
```

### Пример: Производитель-Потребитель с Message Passing

```c
#define N 100

typedef struct {
    int data;
} Message;

// Процесс производителя:
void producer() {
    Message msg;
    while (true) {
        msg.data = produce_item();
        
        // Отправить сообщение потребителю
        send(CONSUMER_ID, msg);
    }
}

// Процесс потребителя:
void consumer() {
    Message msg;
    while (true) {
        // Получить сообщение от производителя
        receive(PRODUCER_ID, &msg);
        
        consume_item(msg.data);
    }
}

// Вариант с почтовым ящиком:
mailbox_t items = create_mailbox();

void producer() {
    Message msg;
    while (true) {
        msg.data = produce_item();
        send(items, msg);
    }
}

void consumer() {
    Message msg;
    while (true) {
        receive(items, &msg);
        consume_item(msg.data);
    }
}
```

### Преимущества Message Passing

- **Безопасность**: Исключает data races на общую память
- **Масштабируемость**: Хорошо работает на распределенных системах
- **Простота**: Явная передача данных
- **Отсутствие deadlock**: Если правильно организовано

### Недостатки Message Passing

- **Производительность**: Медленнее shared memory (копирование сообщений)
- **Сложность**: Требует явной организации архитектуры
- **Deadlock возможен**: При неправильной синхронизации

### Барьеры (Barriers)

**Определение**: Синхронизационный примитив, который заставляет несколько потоков ждать друг друга в определенной точке кода.

**Концепция:**
```
Все потоки должны достичь точки синхронизации (барьера)
перед тем как любой из них может продолжить выполнение.

Поток 1:                  Поток 2:                  Поток 3:
  код 1                     код 2                     код 3
  barrier_wait()            barrier_wait()            barrier_wait()
  (ждет)                    (ждет)                    (ждет)
          ↓ Все 3 потока синхронизировались ↓
  код 4                     код 5                     код 6
```

### Реализация Барьера

**Структура:**
```c
typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int count;        // Сколько потоков уже достигло барьера
    int total;        // Всего потоков
} barrier_t;

void barrier_init(barrier_t *b, int n_threads) {
    b->count = 0;
    b->total = n_threads;
    pthread_mutex_init(&b->mutex, NULL);
    pthread_cond_init(&b->cond, NULL);
}
```

**Barrier Wait операция:**
```c
void barrier_wait(barrier_t *b) {
    pthread_mutex_lock(&b->mutex);
    
    b->count++;  // Увеличить счетчик пришедших потоков
    
    if (b->count == b->total) {
        // Последний поток - разбудить всех
        b->count = 0;  // Сбросить счетчик для следующего раунда
        pthread_cond_broadcast(&b->cond);  // Пробудить всех
    } else {
        // Не последний - ждать
        pthread_cond_wait(&b->cond, &b->mutex);
    }
    
    pthread_mutex_unlock(&b->mutex);
}
```

### Пример использования Барьера

**Параллельное вычисление:**
```c
#define NUM_THREADS 4
barrier_t barrier;

void *thread_work(void *arg) {
    int id = *(int *)arg;
    
    // Фаза 1: Расчет локальных данных
    printf("Thread %d: Phase 1\n", id);
    compute_local_data(id);
    
    // Ждем, пока все потоки завершат фазу 1
    barrier_wait(&barrier);
    
    // Фаза 2: Использование данных других потоков
    printf("Thread %d: Phase 2\n", id);
    use_other_data();
    
    // Ждем, пока все потоки завершат фазу 2
    barrier_wait(&barrier);
    
    // Фаза 3: Финальный расчет
    printf("Thread %d: Phase 3\n", id);
    final_compute();
    
    return NULL;
}

int main() {
    pthread_t threads[NUM_THREADS];
    int ids[NUM_THREADS];
    
    barrier_init(&barrier, NUM_THREADS);
    
    for (int i = 0; i < NUM_THREADS; i++) {
        ids[i] = i;
        pthread_create(&threads[i], NULL, thread_work, &ids[i]);
    }
    
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }
    
    return 0;
}
```

**Вывод:**
```
Thread 0: Phase 1
Thread 1: Phase 1
Thread 2: Phase 1
Thread 3: Phase 1
Thread 0: Phase 2       // Все потоки синхронизировались
Thread 1: Phase 2
Thread 2: Phase 2
Thread 3: Phase 2
Thread 0: Phase 3
Thread 1: Phase 3
Thread 2: Phase 3
Thread 3: Phase 3
```

### Применение Барьеров

**1. SIMD операции:**
```c
// Фаза чтения данных
read_data();
barrier_wait();  // Все потоки должны прочитать

// Фаза обработки
process_data();
barrier_wait();  // Все потоки должны обработать

// Фаза записи результатов
write_results();
```

**2. Итерационные вычисления:**
```c
for (int iter = 0; iter < ITERATIONS; iter++) {
    compute_iteration(thread_id);
    barrier_wait();  // Синхронизация между итерациями
}
```

**3. Map-Reduce операции:**
```c
// Map фаза
map_operation(my_data);
barrier_wait();  // Дождаться всех

// Reduce фаза
reduce_operation();
barrier_wait();  // Дождаться всех

// Finalize
finalize();
```

### Производительность Барьеров

**Простой Barrier (как выше):**
- O(1) для каждого потока
- Всего потоков + broadcast = O(n)
- Проблема: broadcast пробуждает всех потоков одновременно (thundering herd)

**Tree Barrier (оптимизированный):**
```
При n потоках в виде дерева:
- Времяхранилищ Depth O(log n)
- Уменьшено пробуждение потоков
- Лучше на многоядерных системах
```

**Butterfly Barrier (для MPI):**
```
Используется в параллельных вычислениях
Обобщает идею дерева для оптимальной синхронизации
```

---

## Итоговое резюме

### Ключевые концепции

1. **Критическая область** - код, доступ к которому должен быть синхронизирован
2. **Race condition** - результат зависит от порядка выполнения потоков
3. **Требования к решению**: Взаимоисключение, Прогресс, Ограниченное ожидание

### Методы синхронизации

| Метод | Когда использовать | Особенности |
|---|---|---|
| **Активное ожидание (Spinlock)** | Коротко на многоядерных системах | Тратит CPU, simple |
| **Семафор** | Контроль ресурсов, универсальная синхронизация | Запоминает сигналы |
| **Мьютекс** | Простое взаимоисключение | Проще чем семафор |
| **Условная переменная** | Сложные условия синхронизации | Требует мьютекс, не запоминает |
| **Message Passing** | Распределенные системы | Безопасно, медленнее |
| **Барьер** | Фазовая синхронизация | Все потоки ждут друг друга |

### Алгоритм Петерсона

- Классическое программное решение для 2 процессов
- Может расширяться на N процессов
- Проблемы с переупорядочением на современных архитектурах
- Требует memory barriers

### Атомарные операции

- **CAS** - основа для lock-free алгоритмов
- **Spinlock** - эффективен на многоядерных системах для коротких CS
- Быстрее чем мьютекс на низкой конфликтности

---

## Дополнительные материалы для углубленного изучения

### Рекомендуемые источники
1. **Tanenbaum, Bos - Современные операционные системы (4-е издание)** - Главы 2.3-2.4
2. **Silberschatz, Galvin, Gagne - Operating System Concepts (10-е издание)** - Глава 6 (Synchronization Tools)
3. **Herlihy & Shavit - The Art of Multiprocessor Programming** - Для продвинутых тем

### Практические примеры

Все примеры кода в этом документе могут быть скомпилированы и запущены:
```bash
# Linux/Unix с POSIX threads
gcc -pthread code.c -o program
./program

# С sanitizer для отладки race conditions
gcc -fsanitize=thread -g -O1 -pthread code.c -o program
./program
```

