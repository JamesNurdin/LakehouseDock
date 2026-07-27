WITH cs_w AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_sq_ft,
        w.w_city
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 500000
      AND cs.cs_quantity BETWEEN 1 AND 5
)
SELECT
    p.p_promo_id,
    cs_w.w_warehouse_id,
    cs_w.cs_sold_date_sk,
    SUM(cs_w.cs_ext_sales_price) AS total_sales,
    SUM(cs_w.cs_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(sr.sr_net_loss) AS total_return_loss
FROM cs_w
JOIN promotion p
    ON cs_w.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE p.p_channel_event = 'N'
  AND p.p_channel_catalog = 'N'
  AND p.p_promo_id = 'AAAAAAAAPAAAAAAA'
  AND ss.ss_sales_price > 20.00
  AND sr.sr_return_quantity >= 1
  AND ss.ss_wholesale_cost < (
        SELECT AVG(cs_ext_sales_price) FROM catalog_sales
    )
GROUP BY p.p_promo_id, cs_w.w_warehouse_id, cs_w.cs_sold_date_sk
HAVING SUM(cs_w.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
