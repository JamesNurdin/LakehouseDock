WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_formulation,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
        i.i_category
    FROM tpcds.item i
    WHERE regexp_like(i.i_formulation, 'goldenrod')
      AND i.i_product_name LIKE '%A%'
),
sales_agg AS (
    SELECT
        concat(s.s_store_name, ' (', s.s_city, ')') AS store_full_name,
        d.d_year,
        f.formulation_number,
        substring(f.i_product_name, 1, 5) AS product_prefix,
        count(DISTINCT ss.ss_ticket_number) AS order_cnt,
        sum(ss.ss_net_profit) AS total_net_profit,
        avg(ss.ss_ext_discount_amt) AS avg_discount_amt,
        sum(ss.ss_quantity) AS total_quantity
    FROM filtered_items f
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = f.i_item_sk
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY
        concat(s.s_store_name, ' (', s.s_city, ')'),
        d.d_year,
        f.formulation_number,
        substring(f.i_product_name, 1, 5)
)
SELECT
    store_full_name,
    d_year,
    formulation_number,
    product_prefix,
    order_cnt,
    total_net_profit,
    avg_discount_amt,
    total_quantity
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 50
