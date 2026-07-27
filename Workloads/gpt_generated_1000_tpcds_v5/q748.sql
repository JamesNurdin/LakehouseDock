WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_cr_amount,
        SUM(cr_return_quantity) AS total_cr_qty
    FROM catalog_returns
    WHERE cr_fee > 20
      AND cr_return_tax < 100
    GROUP BY cr_item_sk, cr_reason_sk
), combined AS (
    SELECT
        ca.ca_state,
        cc.cc_name,
        i.i_item_id,
        i.i_product_name,
        r.r_reason_desc,
        td.t_hour,
        cr_agg.total_cr_amount,
        wr.wr_return_amt,
        SUM(wr.wr_return_amt) OVER (PARTITION BY i.i_item_id ORDER BY td.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_web_return,
        cr_agg.total_cr_amount + SUM(wr.wr_return_amt) OVER (PARTITION BY i.i_item_id ORDER BY td.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_return_amount
    FROM cr_agg
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cr_agg.cr_item_sk
       AND cr.cr_reason_sk = cr_agg.cr_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_reason_sk = r.r_reason_sk
       AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca2
        ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND ca.ca_country = 'United States'
      AND i.i_current_price BETWEEN 10 AND 1000
      AND r.r_reason_desc LIKE '%damage%'
      AND td.t_hour BETWEEN 8 AND 20
      AND wr.wr_return_quantity > 1
)
SELECT DISTINCT
    ca_state,
    cc_name,
    i_item_id,
    i_product_name,
    r_reason_desc,
    t_hour,
    total_cr_amount,
    cumulative_web_return,
    total_return_amount,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amount DESC) AS reason_item_rank
FROM combined
ORDER BY reason_item_rank, total_return_amount DESC
LIMIT 100
