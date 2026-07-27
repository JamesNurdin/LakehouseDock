WITH returns_agg AS (
    SELECT
        cc.cc_company_name,
        cc.cc_division_name,
        wp.wp_type,
        d_ret.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_ids
    FROM
        web_returns wr
        JOIN date_dim d_ret
            ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN call_center cc
            ON cc.cc_closed_date_sk = d_ret.d_date_sk
    WHERE
        d_ret.d_year = 2000
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_char_count > 1000
        AND wr.wr_return_quantity >= 10
        AND wr.wr_return_tax < 50
        AND cc.cc_country = 'United States'
    GROUP BY
        cc.cc_company_name,
        cc.cc_division_name,
        wp.wp_type,
        d_ret.d_year
)
SELECT
    cc_company_name,
    cc_division_name,
    wp_type,
    d_year,
    total_net_loss,
    total_return_qty,
    distinct_page_ids,
    CASE WHEN total_net_loss > 500 THEN 'High' ELSE 'Moderate' END AS loss_category,
    RANK() OVER (PARTITION BY cc_company_name ORDER BY total_net_loss DESC) AS loss_rank
FROM returns_agg
ORDER BY total_net_loss DESC
LIMIT 100
