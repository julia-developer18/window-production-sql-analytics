-- DDL производственной схемы оконного предприятия (IT-Окна)

-- 1. Справочник сырья и материалов
CREATE TABLE spr_mat (
    id_mat INT PRIMARY KEY,
    id_group INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    art VARCHAR(50),
    unit VARCHAR(10),
    h_prof NUMERIC(10, 2), -- высота профиля
    massa NUMERIC(10, 3),  -- масса единицы
    prc_waste NUMERIC(5, 2) -- нормативный процент отходов
);

-- 2. Готовые конструкции в заказах (Окна / Балконные блоки)
CREATE TABLE doc_acc_cnt (
    id_doc INT NOT NULL,
    id_str INT NOT NULL,
    ordno INT,
    name VARCHAR(100) NOT NULL,
    w NUMERIC(10, 2) NOT NULL,      -- ширина, мм
    h NUMERIC(10, 2) NOT NULL,      -- высота, мм
    f_sqrt NUMERIC(10, 3) NOT NULL, -- площадь изделия, м2
    kol INT DEFAULT 1,              -- количество изделий
    zena NUMERIC(12, 2),            -- себестоимость расчетная
    zena_exp NUMERIC(12, 2),        -- цена продажи
    syma NUMERIC(12, 2),            -- итоговая сумма со скидкой
    calc_error INT DEFAULT 0,       -- флаг ошибки расчета (0 = ОК)
    zena_is_manual INT DEFAULT 0,   -- флаг ручной корректировки цены
    PRIMARY KEY (id_doc, id_str)
);

-- 3. Производственная спецификация (BOM / состав конструкции)
CREATE TABLE doc_acc_cnt_detals (
    id_doc INT NOT NULL,
    id_str INT NOT NULL,
    id_detal INT NOT NULL,
    id_mat INT NOT NULL REFERENCES spr_mat(id_mat),
    kol NUMERIC(12, 4) NOT NULL,     -- норма расхода материала
    zena_seb NUMERIC(12, 2) NOT NULL, -- себестоимость единицы материала
    zena_exp NUMERIC(12, 2) NOT NULL, -- отпускная цена единицы материала
    syma_seb NUMERIC(12, 2) NOT NULL, -- сумма по строке в закупочных ценах
    syma NUMERIC(12, 2) NOT NULL,     -- сумма по строке в отпускных ценах
    massa NUMERIC(10, 3),             -- масса позиции
    zena_is_manual INT DEFAULT 0,     -- ручная цена на деталь
    PRIMARY KEY (id_doc, id_str, id_detal),
    FOREIGN KEY (id_doc, id_str) REFERENCES doc_acc_cnt(id_doc, id_str)
);

-- Индексы для ускорения аналитических выборок
CREATE INDEX idx_cnt_details_order ON doc_acc_cnt_detals(id_doc, id_str);
CREATE INDEX idx_cnt_details_mat ON doc_acc_cnt_detals(id_mat);
