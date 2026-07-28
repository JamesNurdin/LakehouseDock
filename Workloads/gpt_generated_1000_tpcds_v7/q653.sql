WITH base AS (
    SELECT
        td.t_time_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_category,
        i.i_brand,
        s.s_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cp.cp_description,
        cp.cp_catalog_number,
        w.w_state AS warehouse_state,
        inv.inv_quantity_on_hand
    FROM time_dim td
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_return_time_sk = td.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
       AND cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_minute IN (6, 12, 13)
      AND td.t_shift = 'first'
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
)
SELECT
    t.category,
    t.brand,
    SUM(t.total_sales) AS sum_sales,
    SUM(t.total_returns) AS sum_returns,
    AVG(t.net_profit) AS avg_net_profit
FROM (
    SELECT
        i_category AS category,
        i_brand AS brand,
        ss_net_paid AS total_sales,
        sr_return_amt AS total_returns,
        (ss_net_paid - sr_return_amt) AS net_profit
    FROM base
) t
GROUP BY t.category, t.brand
HAVING SUM(t.total_sales) > 10000
ORDER BY sum_sales DESC
LIMIT 100
