WITH filtered_store AS (
    SELECT sr.sr_ticket_number,
           sr.sr_customer_sk,
           sr.sr_return_amt,
           sr.sr_return_quantity,
           sr.sr_net_loss,
           sr.sr_returned_date_sk,
           sr.sr_return_time_sk,
           sr.sr_item_sk,
           sr.sr_reason_sk
    FROM   store_returns sr
    WHERE  sr.sr_return_amt > 10
      AND  sr.sr_return_quantity > 0
),
filtered_web AS (
    SELECT wr.wr_order_number,
           wr.wr_refunded_customer_sk,
           wr.wr_return_amt,
           wr.wr_return_quantity,
           wr.wr_returned_date_sk,
           wr.wr_returned_time_sk,
           wr.wr_item_sk,
           wr.wr_reason_sk,
           wr.wr_web_page_sk
    FROM   web_returns wr
    WHERE  wr.wr_return_amt > 5
      AND  wr.wr_return_quantity > 0
),
key_diff AS (
    SELECT sr_ticket_number FROM filtered_store
    EXCEPT
    SELECT wr_order_number FROM filtered_web
),
key_inter AS (
    SELECT sr_customer_sk FROM filtered_store
    INTERSECT
    SELECT wr_refunded_customer_sk FROM filtered_web
),
base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        rd.d_year,
        rd.d_week_seq,
        td.t_hour,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        wr.wr_order_number,
        wr.wr_return_amt            AS web_return_amt,
        wp.wp_type,
        wp.wp_url,
        CASE
            WHEN rd.d_week_seq % 2 = 0 THEN 'EvenWeek'
            ELSE 'OddWeek'
        END                           AS week_parity
    FROM   store_returns sr
    JOIN   date_dim rd   ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN   time_dim td   ON sr.sr_return_time_sk = td.t_time_sk
    JOIN   item i        ON sr.sr_item_sk = i.i_item_sk
    JOIN   reason r      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN   web_returns wr
           ON wr.wr_returned_date_sk = rd.d_date_sk
          AND wr.wr_returned_time_sk = td.t_time_sk
          AND wr.wr_item_sk = i.i_item_sk
          AND wr.wr_reason_sk = r.r_reason_sk
    JOIN   web_page wp   ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE  rd.d_year = 2001
      AND  rd.d_week_seq = 3
      AND  td.t_hour BETWEEN 9 AND 17
      AND  i.i_category = 'Sports'
      AND  r.r_reason_desc LIKE '%color%'
      AND  wp.wp_type = 'ad'
      AND  EXISTS (
            SELECT 1
            FROM   web_page wp2
            WHERE  wp2.wp_creation_date_sk = rd.d_date_sk
              AND  wp2.wp_type = 'dynamic'
        )
),
final_set AS (
    SELECT *
    FROM   base
    WHERE  sr_ticket_number IN (SELECT sr_ticket_number FROM key_diff)
      AND  sr_customer_sk   IN (SELECT sr_customer_sk   FROM key_inter)
)
SELECT
    week_parity,
    d_year,
    i_category,
    i_brand,
    COUNT(DISTINCT sr_ticket_number)      AS store_return_cnt,
    SUM(sr_return_amt)                    AS total_store_return_amt,
    AVG(web_return_amt)                   AS avg_web_return_amt,
    MIN(sr_net_loss)                      AS min_net_loss,
    MAX(sr_net_loss)                      AS max_net_loss
FROM   final_set
GROUP BY
    week_parity,
    d_year,
    i_category,
    i_brand
ORDER BY
    total_store_return_amt DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
