WITH inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_quantity_returned,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_net_loss,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(COALESCE(ia.total_qty_on_hand, 0)) AS avg_inventory_on_hand
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
    AND s.s_store_sk = sr.sr_store_sk
LEFT JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
    AND ia.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name
ORDER BY total_sales_amount DESC
LIMIT 100
