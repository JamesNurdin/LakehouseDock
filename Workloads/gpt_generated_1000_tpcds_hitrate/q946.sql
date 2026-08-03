WITH aggregated_returns AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        cp.cp_department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_year, w.w_warehouse_name, cp.cp_department
),

aggregated_sales AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, w.w_warehouse_name, cd.cd_gender
),

inventory_agg AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY d.d_year, w.w_warehouse_name
),

web_returns_agg AS (
    SELECT
        d.d_year,
        s.web_name,
        SUM(wr.wr_net_loss) AS web_return_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    GROUP BY d.d_year, s.web_name
)

SELECT
    COALESCE(ar.d_year, asales.d_year, iagg.d_year, wrag.d_year) AS year,
    COALESCE(ar.w_warehouse_name, asales.w_warehouse_name, iagg.w_warehouse_name) AS warehouse,
    ar.cp_department,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.loss_category,
    asales.total_net_profit,
    asales.total_quantity,
    asales.order_cnt,
    iagg.total_on_hand,
    wrag.web_name,
    wrag.web_return_net_loss,
    wrag.web_return_cnt,
    RANK() OVER (
        PARTITION BY COALESCE(ar.d_year, asales.d_year, iagg.d_year, wrag.d_year)
        ORDER BY COALESCE(ar.total_return_amount, 0) DESC
    ) AS return_amount_rank
FROM aggregated_returns ar
FULL OUTER JOIN aggregated_sales asales
    ON ar.d_year = asales.d_year
   AND ar.w_warehouse_name = asales.w_warehouse_name
FULL OUTER JOIN inventory_agg iagg
    ON COALESCE(ar.d_year, asales.d_year) = iagg.d_year
   AND COALESCE(ar.w_warehouse_name, asales.w_warehouse_name) = iagg.w_warehouse_name
FULL OUTER JOIN web_returns_agg wrag
    ON COALESCE(ar.d_year, asales.d_year, iagg.d_year) = wrag.d_year
CROSS JOIN (
    SELECT d_year FROM date_dim WHERE d_year IN (1998, 1999) GROUP BY d_year
) dy
CROSS JOIN (
    VALUES (1), (2)
) t(dummy)
WHERE (ar.total_return_amount > 5000 OR asales.total_net_profit > 2000 OR iagg.total_on_hand > 1000)
  AND COALESCE(ar.d_year, asales.d_year, iagg.d_year, wrag.d_year) >= 1998
  AND COALESCE(ar.w_warehouse_name, asales.w_warehouse_name, iagg.w_warehouse_name) IS NOT NULL
LIMIT 100
