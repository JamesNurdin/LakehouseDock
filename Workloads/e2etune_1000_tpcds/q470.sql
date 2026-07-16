WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        d_sales.d_year,
        d_sales.d_quarter_name,
        hd_bill.hd_demo_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    WHERE cc.cc_state IN ('TN', 'GA')
      AND d_sales.d_year = 2020
      AND d_sales.d_quarter_name = 'Q1'
      AND hd_bill.hd_vehicle_count >= 2
      AND (cc.cc_open_date_sk IS NULL OR d_sales.d_date_sk >= cc.cc_open_date_sk)
      AND (cc.cc_closed_date_sk IS NULL OR d_sales.d_date_sk <= cc.cc_closed_date_sk)
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        d_sales.d_year,
        d_sales.d_quarter_name,
        hd_bill.hd_demo_sk
    HAVING SUM(cs.cs_net_profit) > 10000
),
returns_agg AS (
    SELECT
        d_return.d_year,
        d_return.d_quarter_name,
        hd_return.hd_demo_sk,
        SUM(sr.sr_net_loss) AS total_returns_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN household_demographics hd_return
        ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
    WHERE d_return.d_year = 2020
      AND d_return.d_quarter_name = 'Q1'
      AND hd_return.hd_vehicle_count >= 2
    GROUP BY
        d_return.d_year,
        d_return.d_quarter_name,
        hd_return.hd_demo_sk
)
SELECT
    s.cc_call_center_id,
    s.cc_name,
    s.cc_state,
    s.d_year,
    s.d_quarter_name,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    (s.total_profit - COALESCE(r.total_returns_loss, 0)) AS net_contribution,
    s.distinct_orders,
    COALESCE(r.distinct_returns, 0) AS distinct_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_quarter_name = r.d_quarter_name
   AND s.hd_demo_sk = r.hd_demo_sk
ORDER BY net_contribution DESC
LIMIT 10
