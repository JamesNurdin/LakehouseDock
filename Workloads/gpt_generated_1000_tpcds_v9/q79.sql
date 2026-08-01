/*
Goal: Compute monthly net profit per item (catalog sales + web sales – returns) for the year 2001, include inventory on‑hand and time‑of‑sale details, rank items by profit within each year and calculate a three‑month moving total. All 14 TPC‑DS tables are joined using only the allowed surrogate‑key relationships and three filter predicates are applied (call center city, year, and item price).
*/
WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d           ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk= cp.cp_catalog_page_sk
    JOIN item i               ON cs.cs_item_sk        = i.i_item_sk
    JOIN time_dim t           ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_city = 'Glendale'
      AND d.d_year = 2001
      AND i.i_current_price > 50
    GROUP BY cs.cs_item_sk,
             cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_sold_time_sk,
             cs.cs_bill_customer_sk,
             cs.cs_bill_cdemo_sk,
             d.d_year,
             d.d_month_seq
),
web_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        MIN(ws.ws_warehouse_sk) AS ws_warehouse_sk,
        MIN(ws.ws_web_page_sk) AS ws_web_page_sk,
        d2.d_year,
        d2.d_month_seq,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d2      ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2      ON ws.ws_sold_time_sk = t2.t_time_sk
    GROUP BY ws.ws_item_sk,
             ws.ws_sold_time_sk,
             d2.d_year,
             d2.d_month_seq
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        MIN(wr.wr_reason_sk) AS reason_sk,
        d3.d_year,
        d3.d_month_seq,
        SUM(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    GROUP BY wr.wr_item_sk,
             d3.d_year,
             d3.d_month_seq
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        d4.d_year,
        d4.d_month_seq,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM inventory inv
    JOIN date_dim d4 ON inv.inv_date_sk = d4.d_date_sk
    GROUP BY inv.inv_item_sk,
             d4.d_year,
             d4.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ca.d_year,
    ca.d_month_seq,
    ca.catalog_profit,
    wa.web_profit,
    COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0) AS total_net_profit,
    ra.return_loss,
    inv.quantity_on_hand,
    t.t_hour AS catalog_sale_hour,
    t2.t_hour AS web_sale_hour,
    r.r_reason_desc,
    RANK() OVER (PARTITION BY ca.d_year ORDER BY (COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0)) DESC) AS profit_rank,
    SUM(COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0))
        OVER (PARTITION BY i.i_item_id ORDER BY ca.d_year, ca.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_three_month_net
FROM catalog_agg ca
LEFT JOIN web_agg wa
       ON ca.cs_item_sk = wa.ws_item_sk
      AND ca.d_year = wa.d_year
      AND ca.d_month_seq = wa.d_month_seq
LEFT JOIN returns_agg ra
       ON ca.cs_item_sk = ra.wr_item_sk
      AND ca.d_year = ra.d_year
      AND ca.d_month_seq = ra.d_month_seq
LEFT JOIN inventory_agg inv
       ON ca.cs_item_sk = inv.inv_item_sk
      AND ca.d_year = inv.d_year
      AND ca.d_month_seq = inv.d_month_seq
JOIN item i        ON ca.cs_item_sk = i.i_item_sk
JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c     ON ca.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ca.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t     ON ca.cs_sold_time_sk = t.t_time_sk
LEFT JOIN time_dim t2 ON wa.ws_sold_time_sk = t2.t_time_sk
LEFT JOIN warehouse w ON wa.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp ON wa.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r    ON ra.reason_sk = r.r_reason_sk
ORDER BY total_net_profit DESC
LIMIT 100
