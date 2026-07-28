WITH
    dr AS (
        SELECT *
        FROM date_dim
        WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ),
    it AS (
        SELECT *
        FROM item
        WHERE i_manufact_id = 350
    )
SELECT
    i.i_category,
    d.d_year,
    cc.cc_name,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_ship_date_sk) AS min_ship_date_sk,
    MAX(ws.ws_ship_date_sk) AS max_ship_date_sk
FROM
    dr d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                      AND ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                            AND cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end   ON p.p_end_date_sk   = d_p_end.d_date_sk
WHERE
    i.i_brand = 'Brand#23'               -- filter on a specific brand
    AND p.p_cost > 1000.00               -- filter on high‑cost promotions
    AND cc.cc_state = 'CA'               -- filter on call centers in California
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d.d_date_sk
          AND cr2.cr_return_amount > 5000
    )
GROUP BY
    i.i_category,
    d.d_year,
    cc.cc_name,
    p.p_promo_name
HAVING
    SUM(cr.cr_return_amount) > 10000
ORDER BY
    total_catalog_returns DESC
LIMIT 100
