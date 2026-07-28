WITH base AS (
    SELECT
        i.i_category,
        cd_sr.cd_gender,
        sr.sr_return_amt,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE i.i_category = 'Shoes'
      AND cd_sr.cd_education_status = 'Advanced Degree'
      AND ws.ws_net_paid_inc_tax > 1000
      AND sr.sr_return_quantity >= 2
      AND i.i_rec_end_date > DATE '2000-01-01'
)
SELECT
    i_category,
    cd_gender,
    total_return_amt,
    total_sales_inc_tax,
    orders_count,
    RANK() OVER (PARTITION BY i_category ORDER BY total_return_amt DESC) AS return_amt_rank
FROM (
    SELECT
        i_category,
        cd_gender,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(ws_net_paid_inc_tax) AS total_sales_inc_tax,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM base
    GROUP BY GROUPING SETS ((i_category, cd_gender), (i_category))
) agg
ORDER BY i_category, return_amt_rank
LIMIT 100
