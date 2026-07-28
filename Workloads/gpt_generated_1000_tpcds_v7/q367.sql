WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_item_desc,
        i.i_item_id,
        i.i_brand,
        i.i_color,
        regexp_extract(i.i_item_id, '([A-Z]+)', 1) AS item_prefix,
        concat(i.i_brand, ' ', i.i_color) AS brand_color,
        sum(ss.ss_net_paid_inc_tax) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(Portable|Wireless)')
    GROUP BY
        i.i_item_sk,
        i.i_category,
        i.i_item_desc,
        i.i_item_id,
        i.i_brand,
        i.i_color
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        sum(wr.wr_return_amt_inc_tax) AS total_returns,
        sum(wr.wr_net_loss) AS total_loss,
        count(*) AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt_inc_tax > 0
    GROUP BY i.i_item_sk
),
page_info AS (
    SELECT
        wr.wr_item_sk,
        wp.wp_url,
        wp.wp_type,
        re.r_reason_desc,
        row_number() OVER (PARTITION BY wr.wr_item_sk ORDER BY wr.wr_returned_date_sk DESC) AS rn
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason re ON wr.wr_reason_sk = re.r_reason_sk
)
SELECT
    s.i_category,
    s.item_prefix,
    s.brand_color,
    s.total_sales,
    s.total_profit,
    coalesce(r.total_returns, 0) AS total_returns,
    coalesce(r.total_loss, 0) AS total_loss,
    (s.total_profit - coalesce(r.total_loss, 0)) AS net_margin,
    coalesce(r.return_cnt, 0) AS return_cnt,
    regexp_extract(p.wp_url, '^(https?://[^/]+)', 1) AS domain,
    substring(p.wp_url, 1, 15) AS url_prefix,
    p.r_reason_desc AS latest_return_reason
FROM sales_agg s
LEFT JOIN returns_agg r ON s.i_item_sk = r.i_item_sk
LEFT JOIN page_info p ON s.i_item_sk = p.wr_item_sk AND p.rn = 1
WHERE p.wp_url LIKE '%electronics%'
  AND regexp_like(p.wp_type, '(article|blog)')
ORDER BY s.total_sales DESC
LIMIT 20
