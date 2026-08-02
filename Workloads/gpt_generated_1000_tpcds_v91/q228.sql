WITH target_stores AS (
    SELECT s_store_sk
    FROM store
    WHERE s_number_employees > 200
    EXCEPT
    SELECT s_store_sk
    FROM store
    WHERE s_number_employees < 50
),
joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_market_id,
        s.s_state,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        cd.cd_education_status,
        cr.cr_return_amount,
        sr.sr_return_amt,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid
    FROM store s
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_market_id IN (1, 3, 7)
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#45'
      AND cd.cd_education_status = 'College'
      AND td.t_shift = 'first'
      AND td.t_minute = 4
      AND cr.cr_return_amount > 50
      AND sr.sr_return_quantity > 1
      AND ws.ws_order_number IN (
          SELECT cr2.cr_order_number
          FROM catalog_returns cr2
          WHERE cr2.cr_return_amount > 100
      )
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt > 100
      )
      AND s.s_store_sk IN (SELECT s_store_sk FROM target_stores)
),
aggregated AS (
    SELECT
        s_market_id,
        s_state,
        i_category,
        i_brand,
        cd_gender,
        cd_education_status,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
        AVG(ws_sales_price) AS avg_ws_sales_price,
        MAX(ws_net_paid) AS max_ws_net_paid,
        MIN(ws_net_paid) AS min_ws_net_paid
    FROM joined_data
    GROUP BY
        s_market_id,
        s_state,
        i_category,
        i_brand,
        cd_gender,
        cd_education_status
)
SELECT
    s_market_id,
    s_state,
    i_category,
    i_brand,
    cd_gender,
    cd_education_status,
    total_catalog_return_amount,
    total_store_return_amount,
    distinct_web_orders,
    avg_ws_sales_price,
    max_ws_net_paid,
    min_ws_net_paid,
    total_catalog_return_amount + total_store_return_amount AS total_return_amount,
    RANK() OVER (ORDER BY total_catalog_return_amount + total_store_return_amount DESC) AS return_amount_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
