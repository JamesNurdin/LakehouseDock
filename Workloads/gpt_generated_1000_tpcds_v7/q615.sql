WITH wr_joined AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_fee,
        wr.wr_order_number,
        d.d_year,
        d.d_dow,
        d.d_current_year,
        i.i_category,
        i.i_brand,
        i.i_category_id,
        s.s_state,
        s.s_gmt_offset
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    d_year,
    i_category,
    s_state,
    COUNT(*) AS return_cnt,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_tax) AS avg_return_tax,
    MIN(wr_fee) AS min_fee,
    MAX(wr_return_quantity) AS max_quantity
FROM wr_joined
WHERE
    d_year = 2002
    AND i_category_id IN (4, 6)
    AND i_brand = 'callyeingeing'
    AND s_state = 'TX'
    AND d_dow = 3
    AND wr_return_tax > 5.00
GROUP BY d_year, i_category, s_state
ORDER BY total_return_amount DESC
LIMIT 100
