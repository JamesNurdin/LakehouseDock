WITH base AS (
    SELECT
        sr.sr_returned_date_sk               AS sr_returned_date_sk,
        sr.sr_return_quantity                AS sr_return_quantity,
        sr.sr_net_loss                       AS sr_net_loss,
        sr.sr_item_sk                        AS sr_item_sk,
        sr.sr_customer_sk                    AS sr_customer_sk,
        sr.sr_store_sk                       AS sr_store_sk,
        sr.sr_reason_sk                      AS sr_reason_sk,
        wr.wr_returned_date_sk               AS wr_returned_date_sk,
        wr.wr_return_quantity                AS wr_return_quantity,
        wr.wr_net_loss                       AS wr_net_loss,
        wr.wr_item_sk                        AS wr_item_sk,
        wr.wr_refunded_customer_sk           AS wr_refunded_customer_sk,
        wr.wr_web_page_sk                    AS wr_web_page_sk,
        i.i_item_id,
        i.i_brand_id,
        i.i_current_price,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        wp.wp_url,
        td_store.t_hour                      AS store_return_hour,
        td_web.t_hour                        AS web_return_hour,
        inv.inv_quantity_on_hand
    FROM store_returns AS sr
    JOIN time_dim AS td_store
        ON sr.sr_return_time_sk = td_store.t_time_sk
    JOIN item AS i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer AS c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics AS hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store AS s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory AS inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN web_returns AS wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim AS td_web
        ON wr.wr_returned_time_sk = td_web.t_time_sk
    JOIN web_page AS wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_birth_year >= 1960
      AND i.i_brand_id = 3001002
      AND s.s_state = 'CA'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND inv.inv_quantity_on_hand > 0
      AND r.r_reason_desc <> 'Damaged'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns AS sr2
          JOIN reason AS r2
              ON sr2.sr_reason_sk = r2.r_reason_sk
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND r2.r_reason_desc = 'Damaged'
      )
)
SELECT
    i_item_id,
    s_store_name,
    s_state,
    COUNT(*)                                 AS total_returns,
    SUM(sr_net_loss + wr_net_loss)           AS total_net_loss,
    AVG(i_current_price)                     AS avg_item_price,
    MIN(sr_return_quantity)                  AS min_store_return_qty,
    MAX(sr_return_quantity)                  AS max_store_return_qty
FROM base
GROUP BY i_item_id, s_store_name, s_state
HAVING SUM(sr_net_loss + wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
