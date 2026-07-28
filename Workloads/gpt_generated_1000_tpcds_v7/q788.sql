WITH sales_base AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100.00
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound >= 50000
      AND cr.cr_fee > 20.00
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    c_customer_id,
    d_year,
    total_sales,
    total_return_loss,
    total_web_return_loss,
    (total_sales - COALESCE(total_return_loss, 0) - COALESCE(total_web_return_loss, 0)) AS net_revenue,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    CASE WHEN total_sales > 50000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM sales_base
ORDER BY d_year, sales_rank
LIMIT 100
