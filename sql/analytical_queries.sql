-- =====================================================================
-- Аналитические SQL-запросы для производственного учета оконных изделий
-- =====================================================================

-- 1. Сводная ведомость конструкций по конкретному заказу
SELECT 
    id_doc,
    id_str,
    name AS construction_name,
    w AS width_mm,
    h AS height_mm,
    f_sqrt AS area_m2,
    kol AS quantity,
    syma AS final_price,
    calc_error
FROM doc_acc_cnt
WHERE id_doc = :id_doc;

-- 2. Детализация спецификации (BOM): расшифровка материалов с ценами
SELECT 
    d.id_doc,
    d.id_str,
    d.id_detal,
    m.name AS material_name,
    m.art AS article_code,
    d.kol AS material_qty,
    d.zena_seb AS unit_cost,
    d.syma_seb AS total_cost_raw,
    d.syma AS total_selling_price
FROM doc_acc_cnt_detals d
JOIN spr_mat m ON d.id_mat = m.id_mat
WHERE d.id_doc = :id_doc AND d.id_str = :id_str;

-- 3. Анализ маржинальности заказа (Расчет фактической валовой прибыли)
-- Сравнивает отпускную стоимость окна и фактическую сумму себестоимости материалов
SELECT 
    c.id_doc,
    c.id_str,
    c.name AS window_name,
    c.syma AS selling_price,
    SUM(d.syma_seb) AS actual_materials_cost,
    (c.syma - SUM(d.syma_seb)) AS gross_profit,
    ROUND(((c.syma - SUM(d.syma_seb)) / NULLIF(c.syma, 0) * 100), 2) AS margin_percent
FROM doc_acc_cnt c
JOIN doc_acc_cnt_detals d 
    ON c.id_doc = d.id_doc AND c.id_str = d.id_str
WHERE c.id_doc = :id_doc
GROUP BY c.id_doc, c.id_str, c.name, c.syma;

-- 4. Контроль качества: поиск конструкций с ошибками проектирования CAD
SELECT 
    id_doc,
    id_str,
    name,
    calc_error,
    f_sqrt AS area_m2
FROM doc_acc_cnt
WHERE calc_error <> 0;

-- 5. Аудит ценообразования: конструкции со спецификацией, измененной вручную
SELECT 
    id_doc,
    id_str,
    id_detal,
    id_mat,
    syma,
    zena_is_manual
FROM doc_acc_cnt_detals
WHERE zena_is_manual = 1;

-- 6. Анализ габаритов: нестандартные крупногабаритные изделия (> 2 м²)
SELECT 
    id_doc,
    id_str,
    name,
    w,
    h,
    f_sqrt
FROM doc_acc_cnt
WHERE f_sqrt > 2.0;

-- 7. Расчет общей массы конструкций для логистики и монтажа
SELECT 
    id_doc,
    id_str,
    SUM(massa) AS total_construction_weight_kg
FROM doc_acc_cnt_detals
GROUP BY id_doc, id_str;

-- 8. Сводная потребность в сырье по группе материалов (для закупки)
SELECT 
    m.id_group,
    m.name AS material_name,
    m.art,
    SUM(d.kol) AS total_quantity_needed,
    SUM(d.syma_seb) AS total_purchase_cost
FROM doc_acc_cnt_detals d
JOIN spr_mat m ON d.id_mat = m.id_mat
WHERE m.id_group = :id_group
GROUP BY m.id_group, m.name, m.art
ORDER BY total_purchase_cost DESC;
