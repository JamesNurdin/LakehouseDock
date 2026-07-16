WITH cleaned_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_desc,
        i.i_product_name,
        i.i_color,
        i.i_size,
        i.i_brand,
        c.c_first_name,
        c.c_last_name,
        regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS clean_desc,
        lower(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '')) AS clean_desc_lower,
        substr(i.i_item_desc, 1, 30) AS short_desc,
        length(i.i_item_desc) AS desc_len,
        concat_ws(' - ', trim(s.s_store_name), trim(s.s_city), trim(i.i_item_desc)) AS store_item_concat,
        length(concat_ws(' - ', trim(s.s_store_name), trim(s.s_city), trim(i.i_item_desc))) AS concat_len,
        lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS customer_full_name_lower,
        position('a' IN lower(i.i_item_desc)) AS pos_first_a,
        split(i.i_item_desc, ' ') AS desc_words,
        element_at(split(i.i_item_desc, ' '), 1) AS first_word_desc,
        reverse(i.i_item_desc) AS rev_desc,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
aggregated AS (
    SELECT
        cs.ss_store_sk,
        cs.d_year,
        cs.d_month_seq,
        cs.clean_desc,
        cs.first_word_desc,
        count(*) AS sales_count,
        sum(cs.ss_ext_sales_price) AS total_sales,
        sum(cs.ss_net_profit) AS total_profit,
        avg(cs.concat_len) AS avg_concat_len,
        max(cs.concat_len) AS max_concat_len,
        array_agg(DISTINCT p.p_promo_name) FILTER (WHERE p.p_promo_name IS NOT NULL) AS promo_names
    FROM cleaned_sales cs
    LEFT JOIN promotion p
        ON cs.ss_item_sk = p.p_item_sk
        AND p.p_start_date_sk <= cs.ss_sold_date_sk
        AND p.p_end_date_sk >= cs.ss_sold_date_sk
    GROUP BY cs.ss_store_sk, cs.d_year, cs.d_month_seq, cs.clean_desc, cs.first_word_desc
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    a.d_year,
    a.d_month_seq,
    a.clean_desc,
    a.first_word_desc,
    a.sales_count,
    format('%,.2f', a.total_sales) AS total_sales_formatted,
    format('%,.2f', a.total_profit) AS total_profit_formatted,
    a.avg_concat_len,
    a.max_concat_len,
    array_join(a.promo_names, ', ') AS promo_names_joined
FROM aggregated a
JOIN store s ON a.ss_store_sk = s.s_store_sk
