WITH base AS (
    SELECT
        d_cr.d_year AS d_year,
        i.i_category AS i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_returns
    FROM catalog_returns cr
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
           AND cc.cc_open_date_sk = d_cr.d_date_sk
           AND cc.cc_closed_date_sk = d_cr.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_ws_site_open
        ON ws_site.web_open_date_sk = d_ws_site_open.d_date_sk
    JOIN date_dim d_ws_site_close
        ON ws_site.web_close_date_sk = d_ws_site_close.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cr.d_date_sk
    WHERE d_cr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_category IN ('Books', 'Sports')
      AND r.r_reason_desc LIKE '%defect%'
      AND cc.cc_state = 'CA'
    GROUP BY ROLLUP (d_cr.d_year, i.i_category)
)
SELECT
    d_year,
    i_category,
    total_sales,
    total_returns,
    total_sales - total_returns AS net_revenue,
    CASE WHEN (total_sales - total_returns) > 100000 THEN 'High' ELSE 'Low' END AS revenue_tier,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    distinct_orders,
    distinct_returns
FROM base
ORDER BY net_revenue DESC
LIMIT 100
