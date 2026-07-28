WITH combined AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name               AS cc_name,
        cc.cc_state              AS cc_state,
        i.i_item_sk,
        i.i_item_id              AS i_item_id,
        i.i_current_price        AS i_current_price,
        p.p_promo_name           AS p_promo_name,
        p.p_discount_active     AS p_discount_active,
        td.t_hour                AS t_hour,
        td.t_minute              AS t_minute,
        cr.cr_return_amount      AS cr_return_amount,
        wr.wr_return_amt         AS wr_return_amt,
        (cr.cr_return_amount + wr.wr_return_amt) AS total_return,
        CASE
            WHEN (cr.cr_return_amount + wr.wr_return_amt) > 200 THEN 'HIGH'
            ELSE 'LOW'
        END                      AS return_category
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND i.i_current_price > 20
      AND cc.cc_state = 'CA'
      AND cr.cr_return_amount > 50
      AND p.p_discount_active = 'Y'
)
SELECT DISTINCT
    cc_name,
    cc_state,
    i_item_id,
    i_current_price,
    p_promo_name,
    t_hour,
    t_minute,
    total_return,
    return_category,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_return DESC) AS state_return_rank
FROM combined
ORDER BY total_return DESC
LIMIT 100
