WITH returns_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_date_sk,
        wr_web_page_sk,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_item_sk, wr_returned_date_sk, wr_web_page_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    ws.web_name,
    SUM(r.total_net_loss) AS agg_net_loss,
    SUM(r.return_cnt) AS total_returns
FROM returns_agg r
JOIN item i
    ON r.wr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON r.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON r.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE
    i.i_current_price > 100
    AND wp.wp_autogen_flag = 'N'
    AND s.s_geography_class <> 'Unknown'
    AND d_ret.d_year = 2001
    AND hd.hd_vehicle_count >= 1
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    ws.web_name
HAVING SUM(r.total_net_loss) > 1000
ORDER BY agg_net_loss DESC
LIMIT 100
