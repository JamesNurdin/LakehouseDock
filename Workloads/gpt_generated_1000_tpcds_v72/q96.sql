WITH base AS (
    SELECT
        cc.cc_division,
        cc.cc_name,
        cc.cc_gmt_offset,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_order_number,
        cs.cs_ext_ship_cost,
        cs.cs_ext_tax,
        cs.cs_net_paid_inc_ship_tax,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_quantity,
        ws.ws_net_paid
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_division IN (1, 3)
      AND cc.cc_gmt_offset > -5
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_ext_tax BETWEEN 20 AND 100
      AND ib.ib_upper_bound <= 150000
      AND ws.ws_quantity >= 5
      AND cr.cr_net_loss > 0
)
SELECT
    cc_division,
    cc_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    AVG(ws_net_paid) AS avg_web_paid,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc_division ORDER BY SUM(cs_net_paid_inc_ship_tax) DESC) AS sales_rank
FROM base
GROUP BY cc_division, cc_name, ib_lower_bound, ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
