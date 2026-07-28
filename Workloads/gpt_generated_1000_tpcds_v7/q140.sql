WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cr.cr_net_loss,
        ws.ws_net_paid,
        p.p_promo_id,
        i.i_container,
        d_sold.d_year,
        cc.cc_state,
        w.w_state,
        ib.ib_lower_bound,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = cs.cs_item_sk
       AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
)
SELECT
    p_promo_id,
    i_container,
    d_year,
    SUM(cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_sales_price) AS avg_sales_price
FROM joined_data
WHERE
    d_year = 2001
    AND i_container IN ('Cup', 'Lb')
    AND ib_lower_bound >= 50000
    AND cc_state = 'CA'
    AND w_state = 'CA'
GROUP BY
    p_promo_id,
    i_container,
    d_year
HAVING
    SUM(cs_net_profit) > 100000
ORDER BY
    total_sales_profit DESC
LIMIT 100
