WITH sales_per_item AS (
    SELECT cs_item_sk,
           sum(cs_sales_price) AS total_sales
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2001
    GROUP BY cs_item_sk
    HAVING sum(cs_sales_price) > 5000
),
cleaned_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]+', ' ')) AS clean_name,
           s.total_sales
    FROM item i
    JOIN sales_per_item s ON i.i_item_sk = s.cs_item_sk
),
tokenized AS (
    SELECT ci.i_item_sk,
           ci.total_sales,
           t.token,
           regexp_like(t.token, '\\d') AS has_digit
    FROM cleaned_items ci
    CROSS JOIN UNNEST(regexp_split(ci.clean_name, '\\s+')) AS t(token)
    WHERE t.token <> '' AND length(t.token) >= 3
),
token_stats AS (
    SELECT token,
           count(DISTINCT i_item_sk) AS distinct_item_count,
           count(*) AS token_occurrences,
           avg(length(token)) AS avg_token_length,
           min(length(token)) AS min_token_length,
           max(length(token)) AS max_token_length,
           sum(total_sales) AS total_sales_for_token,
           sum(CASE WHEN has_digit THEN 1 ELSE 0 END) AS digit_token_occurrences
    FROM tokenized
    GROUP BY token
),
ranked_tokens AS (
    SELECT token,
           distinct_item_count,
           token_occurrences,
           avg_token_length,
           min_token_length,
           max_token_length,
           total_sales_for_token,
           digit_token_occurrences,
           row_number() OVER (ORDER BY token_occurrences DESC) AS rn
    FROM token_stats
)
SELECT
    token,
    distinct_item_count,
    token_occurrences,
    avg_token_length,
    min_token_length,
    max_token_length,
    total_sales_for_token,
    digit_token_occurrences,
    concat('Prefixed_', token) AS prefixed_token,
    concat(token, '_Suffixed') AS suffixed_token,
    reverse(token) AS reversed_token,
    substr(token, 1, 3) AS token_prefix3,
    substr(token, length(token) - 2, 3) AS token_suffix3,
    format('Token %s appears %s times across %s items, total sales %.2f, digit tokens %s', token, token_occurrences, distinct_item_count, total_sales_for_token, digit_token_occurrences) AS description
FROM ranked_tokens
WHERE rn <= 20
ORDER BY token_occurrences DESC
