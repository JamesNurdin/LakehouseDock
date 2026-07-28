WITH avg_loss AS (
    SELECT avg(sr_net_loss) AS avg_net_loss
    FROM store_returns
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(sr.sr_net_loss) > 2 * avg_loss.avg_net_loss THEN 'High Loss'
        ELSE 'Normal Loss'
    END AS loss_category,
    REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)') AS item_desc_first_word,
    CONCAT(s.s_store_name, ' - ', s.s_city) AS store_location
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN avg_loss
WHERE
    REGEXP_LIKE(s.s_store_name, '(?i)mart|market')
    AND s.s_city LIKE 'New%'
    AND d.d_year = 2002
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
        WHERE cs.cs_item_sk = i.i_item_sk
          AND d2.d_year = 2002
          AND cs.cs_quantity > 5
    )
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    i.i_item_desc,
    s.s_city,
    avg_loss.avg_net_loss,
    REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)'),
    CONCAT(s.s_store_name, ' - ', s.s_city)
HAVING
    SUM(sr.sr_net_loss) > 1000
ORDER BY
    total_net_loss DESC
LIMIT 100
