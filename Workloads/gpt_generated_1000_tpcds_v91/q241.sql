WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_division,
        d_date.d_year,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_order_number,
        sr.sr_item_sk,
        cr.cr_item_sk,
        ca.ca_state,
        hd.hd_vehicle_count,
        cd.cd_gender,
        w.w_warehouse_name,
        w.w_warehouse_sk
    FROM call_center cc
    JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_date
        ON cr.cr_returned_date_sk = d_date.d_date_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_date.d_date_sk
           AND sr.sr_cdemo_sk = cd.cd_demo_sk
           AND sr.sr_hdemo_sk = hd.hd_demo_sk
           AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_date.d_date_sk
           AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
           AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
           AND ws.ws_bill_addr_sk = ca.ca_address_sk
           AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        cc.cc_division IN (2, 3, 4)
        AND d_date.d_year BETWEEN 2000 AND 2002
        AND hd.hd_vehicle_count >= 0
        AND ca.ca_state = 'CA'
        AND w.w_country = 'United States'
        AND ws.ws_quantity > 5
        AND cr.cr_fee > 20
        AND cd.cd_gender = 'M'
),
agg AS (
    SELECT
        cc_division,
        d_year,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        SUM(cr_net_loss) AS total_cr_net_loss,
        SUM(sr_return_amt) AS total_sr_return_amt,
        SUM(sr_net_loss) AS total_sr_net_loss,
        SUM(ws_net_profit) AS total_ws_net_profit,
        COUNT(DISTINCT ws_order_number) AS distinct_ws_orders,
        COUNT(*) AS transaction_cnt
    FROM base
    GROUP BY cc_division, d_year
)
SELECT
    ag.cc_division,
    ag.d_year,
    AVG(ag.total_cr_net_loss + ag.total_sr_net_loss - ag.total_ws_net_profit) AS avg_combined_loss,
    SUM(ag.total_return_amount) AS sum_return_amount,
    MAX(ag.distinct_ws_orders) AS max_distinct_ws_orders,
    (
        SELECT COUNT(DISTINCT ws_sub.ws_order_number)
        FROM web_sales ws_sub
        JOIN date_dim d_sub ON ws_sub.ws_sold_date_sk = d_sub.d_date_sk
        WHERE d_sub.d_year = ag.d_year
          AND ws_sub.ws_warehouse_sk = (
                SELECT w2.w_warehouse_sk
                FROM warehouse w2
                WHERE w2.w_country = 'United States'
                LIMIT 1
            )
    ) AS yearly_distinct_ws_orders
FROM agg ag
WHERE EXISTS (
    SELECT 1
    FROM call_center cc_exists
    WHERE cc_exists.cc_division = ag.cc_division
      AND cc_exists.cc_tax_percentage > 0.10
)
GROUP BY ag.cc_division, ag.d_year
HAVING
    AVG(ag.total_cr_net_loss + ag.total_sr_net_loss - ag.total_ws_net_profit) > 0
    AND SUM(ag.total_return_amount) > 5000
ORDER BY avg_combined_loss DESC
LIMIT 100
