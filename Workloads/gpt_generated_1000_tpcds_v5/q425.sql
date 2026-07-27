WITH promo_detail AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_cost,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_channel_radio,
        p.p_channel_email,
        p.p_discount_active,
        d_start.d_fy_year,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date
    FROM promotion AS p
    JOIN date_dim AS d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim AS d_end   ON p.p_end_date_sk = d_end.d_date_sk
    WHERE p.p_channel_radio = 'N'
      AND p.p_discount_active = 'Y'
      AND d_start.d_fy_year = 1916
)
SELECT
    i.i_item_id,
    i.i_brand,
    pd.d_fy_year,
    SUM(pd.p_cost) AS total_promo_cost,
    COUNT(*) AS promo_cnt,
    CASE WHEN MAX(pd.p_channel_email) = 'Y' THEN 'HasEmail' ELSE 'NoEmail' END AS email_channel_flag,
    RANK() OVER (PARTITION BY pd.d_fy_year ORDER BY SUM(pd.p_cost) DESC) AS cost_rank,
    ROW_NUMBER() OVER (PARTITION BY pd.d_fy_year ORDER BY COUNT(*) DESC) AS promo_cnt_rownum
FROM promo_detail AS pd
JOIN item AS i ON pd.p_item_sk = i.i_item_sk
WHERE i.i_container = 'Unknown'
  AND EXISTS (
        SELECT 1
        FROM promotion AS p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
          AND p2.p_channel_event = 'N'
    )
GROUP BY i.i_item_id, i.i_brand, pd.d_fy_year
HAVING SUM(pd.p_cost) > 1000
ORDER BY pd.d_fy_year, cost_rank
