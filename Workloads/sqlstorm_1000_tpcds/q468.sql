WITH product_agg AS (
    SELECT
        cs.cs_item_sk AS product_id,
        i.i_product_name,
        sum(cs.cs_ext_sales_price) AS total_sales,
        lower(regexp_replace(concat_ws(' ', i.i_product_name, i.i_item_desc, i.i_color, i.i_size, i.i_brand, i.i_class, i.i_category, coalesce(p.p_promo_name, '')), '[^a-z0-9 ]', '')) AS cleaned_desc,
        lower(regexp_replace(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name), '[^a-z0-9 ]', '')) AS cleaned_customer_name,
        lower(regexp_replace(ca.ca_city, '[^a-z0-9 ]', '')) AS cleaned_city,
        lower(regexp_replace(cc.cc_name, '[^a-z0-9 ]', '')) AS cleaned_call_center,
        upper(cc.cc_name) AS cc_name_upper,
        replace(cc.cc_state, ' ', '-') AS dash_state,
        substring(d.d_date_id, 1, 4) AS year_str,
        regexp_extract(p.p_promo_name, '\\d+', 0) AS promo_digits,
        length(lower(i.i_product_name)) AS product_name_len,
        length(lower(c.c_first_name)) AS first_name_len,
        trim(i.i_brand) AS trimmed_brand,
        substring(i.i_item_desc, 1, 30) AS item_desc_prefix,
        regexp_replace(i.i_item_desc, '\\s+', ' ') AS normalized_desc
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT min(d_date_sk) FROM date_dim WHERE d_year = 1998) AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 1998)
    GROUP BY
        cs.cs_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        i.i_brand,
        i.i_class,
        i.i_category,
        p.p_promo_name,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cc.cc_name,
        cc.cc_state,
        d.d_date_id
),
ranked_products AS (
    SELECT
        *,
        row_number() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM product_agg
),
token_counts AS (
    SELECT
        rp.product_id,
        rp.i_product_name,
        rp.total_sales,
        rp.sales_rank,
        token,
        count(*) AS token_count,
        rp.cc_name_upper,
        rp.dash_state,
        rp.year_str,
        rp.product_name_len,
        rp.first_name_len,
        rp.trimmed_brand,
        rp.item_desc_prefix,
        rp.normalized_desc
    FROM ranked_products rp
    CROSS JOIN UNNEST(split(rp.cleaned_desc, ' ')) AS t(token)
    WHERE rp.sales_rank <= 5
      AND token <> ''
    GROUP BY
        rp.product_id,
        rp.i_product_name,
        rp.total_sales,
        rp.sales_rank,
        token,
        rp.cc_name_upper,
        rp.dash_state,
        rp.year_str,
        rp.product_name_len,
        rp.first_name_len,
        rp.trimmed_brand,
        rp.item_desc_prefix,
        rp.normalized_desc
)
SELECT
    product_id,
    i_product_name,
    total_sales,
    sales_rank,
    token,
    token_count,
    cc_name_upper,
    dash_state,
    year_str,
    product_name_len,
    first_name_len,
    trimmed_brand,
    item_desc_prefix,
    normalized_desc
FROM token_counts
ORDER BY total_sales DESC, token_count DESC
LIMIT 100
