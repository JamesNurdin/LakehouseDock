WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cc.cc_division,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        sm.sm_type,
        td.t_hour,
        td.t_am_pm,
        ca.ca_state,
        cd.cd_gender,
        w.word
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN LATERAL (
        SELECT split(i.i_item_desc, ' ') AS words
    ) AS arr ON true
    LEFT JOIN UNNEST(arr.words) AS w(word) ON true
    WHERE cc.cc_division IN (1, 3, 5, 6)
      AND i.i_current_price BETWEEN 10 AND 500
      AND td.t_am_pm = 'PM'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = cr.cr_order_number
      )
),
aggregated AS (
    SELECT
        cc_division AS division,
        i_brand AS brand,
        i_category AS category,
        SUM(cr_net_loss) AS total_loss,
        COUNT(*) AS cnt
    FROM base
    GROUP BY cc_division, i_brand, i_category
)
SELECT AVG(total_loss) AS avg_total_loss
FROM aggregated
WHERE cnt > 5
HAVING AVG(total_loss) > 500
