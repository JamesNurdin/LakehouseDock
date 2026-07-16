WITH sales_strings AS (
    SELECT 
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        s.s_store_name AS entity_name,
        concat_ws(' ', s.s_store_name, c.c_first_name, c.c_last_name, i.i_item_desc) AS raw_string
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT 
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_name AS entity_name,
        concat_ws(' ', cc.cc_name, c.c_first_name, c.c_last_name, i.i_item_desc) AS raw_string
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT 
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        wp.wp_url AS entity_name,
        concat_ws(' ', wp.wp_url, c.c_first_name, c.c_last_name, i.i_item_desc) AS raw_string
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
processed AS (
    SELECT
        ss.channel,
        ss.date_sk,
        ss.entity_name,
        ss.raw_string,
        regexp_replace(lower(ss.raw_string), '[^a-z0-9]', '') AS clean_str,
        reverse(regexp_replace(lower(ss.raw_string), '[^a-z0-9]', '')) AS rev_str,
        length(regexp_replace(lower(ss.raw_string), '[^a-z0-9]', '')) AS str_len,
        length(regexp_replace(regexp_replace(lower(ss.raw_string), '[^a-z0-9]', ''), '[^aeiou]', '')) AS vowel_cnt,
        substring(reverse(regexp_replace(lower(ss.raw_string), '[^a-z0-9]', '')), 1, 20) AS substr_rev_20
    FROM sales_strings ss
),
aggregated AS (
    SELECT
        p.channel,
        d.d_year AS d_year,
        COUNT(*) AS total_sales,
        AVG(p.str_len) AS avg_len,
        approx_percentile(p.str_len, 0.5) AS median_len,
        AVG(p.vowel_cnt) AS avg_vowel_cnt,
        SUM(CASE WHEN p.rev_str = p.clean_str THEN 1 ELSE 0 END) AS palindrome_cnt,
        MAX(p.substr_rev_20) AS max_rev_prefix_20
    FROM processed p
    JOIN date_dim d ON p.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY p.channel, d.d_year
)
SELECT
    a.channel,
    a.d_year,
    a.total_sales,
    a.avg_len,
    a.median_len,
    a.avg_vowel_cnt,
    a.palindrome_cnt,
    a.max_rev_prefix_20,
    ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.avg_len DESC) AS channel_len_rank
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 50
