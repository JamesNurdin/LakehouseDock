WITH
sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        s.s_store_name,
        i.i_class,
        i.i_category,
        SUM(ss.ss_net_paid)          AS total_net_paid,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        COUNT(*)                     AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s         ON ss.ss_store_sk   = s.s_store_sk
    JOIN item i          ON ss.ss_item_sk    = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_class = 'hockey'
      AND s.s_state = 'CA'
    GROUP BY ss.ss_item_sk, ss.ss_store_sk, s.s_store_name, i.i_class, i.i_category
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*)               AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r   ON sr.sr_reason_sk        = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk, sr.sr_store_sk
),
inventory_latest AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amt,
        SUM(cs.cs_net_paid)        AS catalog_net_paid
    FROM catalog_sales cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_type = 'F'
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS cat_return_amt,
        COUNT(*)                 AS cat_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r     ON cr.cr_reason_sk        = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
      AND r.r_reason_desc LIKE '%Damaged%'
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS web_return_amt,
        COUNT(*)               AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r   ON wr.wr_reason_sk        = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Defective'
    GROUP BY wr.wr_item_sk
)
SELECT
    sagg.s_store_name,
    sagg.i_class,
    sagg.total_net_paid,
    sagg.total_net_profit,
    COALESCE(ragg.total_return_amt, 0)   AS store_return_amount,
    COALESCE(inv.qty_on_hand, 0)        AS inventory_on_hand,
    COALESCE(csag.catalog_sales_amt, 0) AS catalog_sales_amount,
    COALESCE(cragg.cat_return_amt, 0)   AS catalog_return_amount,
    COALESCE(wrag.web_return_amt, 0)    AS web_return_amount,
    RANK() OVER (PARTITION BY sagg.s_store_name ORDER BY sagg.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN sagg.total_net_profit > COALESCE(cls.avg_profit, 0) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_class
FROM sales_agg sagg
LEFT JOIN returns_agg ragg
    ON sagg.ss_item_sk = ragg.sr_item_sk
   AND sagg.ss_store_sk = ragg.sr_store_sk
LEFT JOIN inventory_latest inv
    ON sagg.ss_item_sk = inv.inv_item_sk
LEFT JOIN catalog_sales_agg csag
    ON sagg.ss_item_sk = csag.cs_item_sk
LEFT JOIN catalog_returns_agg cragg
    ON sagg.ss_item_sk = cragg.cr_item_sk
LEFT JOIN web_returns_agg wrag
    ON sagg.ss_item_sk = wrag.wr_item_sk
LEFT JOIN warehouse w
    ON csag.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN (
    SELECT i_class, AVG(total_net_profit) AS avg_profit
    FROM sales_agg
    GROUP BY i_class
) cls
    ON sagg.i_class = cls.i_class
WHERE w.w_state = 'CA'
ORDER BY sagg.s_store_name, profit_rank
