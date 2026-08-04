WITH returns_by_store_date AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        i.i_brand,
        d.d_date,
        SUM(sr.sr_net_loss) AS daily_net_loss,
        REGEXP_EXTRACT(i.i_item_desc, '^(\\w+)', 1) AS first_word_desc,
        CONCAT(s.s_store_name, ' - ', i.i_brand) AS store_brand
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2021
      AND s.s_store_name LIKE '%Market%'
      AND REGEXP_LIKE(i.i_item_desc, '(Glass|Metal)')
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        i.i_brand,
        d.d_date,
        i.i_item_desc,
        r.r_reason_sk
),
brand_avg AS (
    SELECT
        i_brand AS brand,
        AVG(daily_net_loss) AS avg_brand_loss
    FROM returns_by_store_date
    GROUP BY i_brand
)
SELECT
    rbs.s_store_id,
    rbs.s_store_name,
    rbs.i_brand,
    ba.avg_brand_loss,
    SUM(rbs.daily_net_loss) OVER (PARTITION BY rbs.s_store_sk, rbs.i_brand) AS total_net_loss,
    SUM(rbs.daily_net_loss) OVER (
        PARTITION BY rbs.s_store_sk
        ORDER BY rbs.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net_loss,
    LAG(rbs.daily_net_loss) OVER (PARTITION BY rbs.s_store_sk ORDER BY rbs.d_date) AS prev_daily_net_loss,
    rbs.first_word_desc,
    rbs.store_brand,
    (SELECT COUNT(*) FROM store_returns) AS overall_return_count
FROM returns_by_store_date rbs
JOIN brand_avg ba ON rbs.i_brand = ba.brand
ORDER BY total_net_loss DESC
LIMIT 100
