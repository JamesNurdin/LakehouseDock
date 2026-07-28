WITH filtered_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_store_credit,
        i.i_class,
        i.i_class_id,
        i.i_item_desc,
        i.i_product_name,
        r.r_reason_desc,
        c.c_salutation,
        cd.cd_gender
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)organic')
      AND i.i_product_name LIKE '%Eco%'
      AND regexp_like(r.r_reason_desc, '\\d{3}')
      AND (c.c_salutation LIKE 'Dr.%' OR c.c_salutation LIKE 'Mr.%')
)
SELECT
    fr.i_class,
    fr.i_class_id,
    regexp_extract(fr.r_reason_desc, '\\d{3}') AS reason_code,
    fr.cd_gender,
    COUNT(*) AS returns_count,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_store_credit) AS avg_store_credit,
    concat(fr.i_class, '-', regexp_extract(fr.r_reason_desc, '\\d{3}')) AS class_reason_key
FROM filtered_returns fr
GROUP BY
    fr.i_class,
    fr.i_class_id,
    regexp_extract(fr.r_reason_desc, '\\d{3}'),
    fr.cd_gender
ORDER BY total_net_loss DESC
LIMIT 10
