WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_warehouse_sk IN (1, 4, 10)
    GROUP BY inv_item_sk, inv_date_sk
),
reason_subset AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%price%'
       OR r_reason_desc LIKE '%service%'
),
ws_filtered AS (
    SELECT ws_sold_date_sk,
           ws_sold_time_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_bill_cdemo_sk,
           ws_web_page_sk,
           ws_net_paid_inc_ship,
           ws_ship_mode_sk
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 2000
      AND ws_ship_mode_sk IN (3, 4, 6, 15, 17)
      AND ws_sold_date_sk BETWEEN 2450000 AND 2453000
)
SELECT
    final.date_sk,
    final.d_year,
    final.c_customer_id,
    final.cd_gender,
    final.reason_desc,
    final.return_category,
    final.rn,
    final.t_hour,
    final.total_on_hand,
    final.wp_url,
    final.letter
FROM (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        d.d_year,
        c.c_customer_id,
        cd.cd_gender,
        r.r_reason_desc AS reason_desc,
        CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_net_loss DESC) AS rn,
        t.t_hour,
        inv_agg.total_on_hand,
        NULL AS wp_url,
        letter
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = cr.cr_item_sk
                         AND inv_agg.inv_date_sk = cr.cr_returned_date_sk
    CROSS JOIN UNNEST(ARRAY['A','B']) AS u(letter)
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
      AND r.r_reason_sk IN (SELECT r_reason_sk FROM reason_subset)
      AND cr.cr_return_quantity BETWEEN 1 AND 5

    UNION DISTINCT

    SELECT
        ws.ws_sold_date_sk AS date_sk,
        d2.d_year,
        c2.c_customer_id,
        cd2.cd_gender,
        (SELECT rsub.r_reason_desc FROM reason_subset rsub LIMIT 1) AS reason_desc,
        CASE WHEN ws.ws_net_paid_inc_ship > 5000 THEN 'High' ELSE 'Low' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY d2.d_year ORDER BY ws.ws_net_paid_inc_ship DESC) AS rn,
        t2.t_hour,
        inv_agg2.total_on_hand,
        wp.wp_url,
        letter
    FROM ws_filtered ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    LEFT JOIN inv_agg inv_agg2 ON inv_agg2.inv_item_sk = ws.ws_item_sk
                                 AND inv_agg2.inv_date_sk = ws.ws_sold_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(ARRAY['C','D']) AS u(letter)
    WHERE d2.d_year BETWEEN 2000 AND 2002
      AND t2.t_hour BETWEEN 0 AND 23
      AND wp.wp_type = 'home page'
      AND EXISTS (SELECT 1 FROM reason_subset rs WHERE rs.r_reason_sk = ws.ws_ship_mode_sk)
) AS final
ORDER BY final.d_year DESC, final.rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
