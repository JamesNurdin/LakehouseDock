WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        -- extract the first numeric token from the promo name (e.g., "Discount 25%" -> "25")
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_num
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '^Discount.*[0-9]{2}%')
      AND p.p_channel_email = 'Y'
)
SELECT
    i.i_brand,
    sm.sm_type,
    CONCAT(i.i_brand, '-', sm.sm_type) AS brand_ship,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    CASE
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(ws.ws_net_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_tier,
    CASE
        WHEN CAST(pf.promo_num AS integer) % 2 = 0 THEN 'EVEN_PROMO'
        ELSE 'ODD_PROMO'
    END AS promo_parity,
    SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS item_desc_prefix
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN promo_filtered pf ON ws.ws_promo_sk = pf.p_promo_sk
WHERE ws.ws_sold_date_sk BETWEEN 2452300 AND 2452400
  AND i.i_item_desc LIKE '%steel%'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_reason_sk IN (
                SELECT r.r_reason_sk
                FROM reason r
                WHERE r.r_reason_desc LIKE '%defect%'
          )
    )
GROUP BY
    i.i_brand,
    sm.sm_type,
    i.i_item_desc,
    pf.promo_num
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC, profit_tier
LIMIT 100
