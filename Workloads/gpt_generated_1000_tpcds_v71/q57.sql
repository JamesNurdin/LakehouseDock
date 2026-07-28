WITH sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS amount,
        COUNT(DISTINCT ws.ws_order_number) AS cnt,
        'sales' AS source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND ca.ca_city LIKE 'San%'
    GROUP BY i.i_category, d.d_year
),
returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        SUM(wr.wr_return_amt) AS amount,
        COUNT(*) AS cnt,
        'returns' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND ca.ca_city LIKE '%York'
    GROUP BY i.i_category, d.d_year
)
SELECT
    i_category,
    d_year,
    CONCAT(i_category, '-', CAST(d_year AS varchar)) AS category_year,
    amount,
    cnt,
    source
FROM (
    SELECT i_category, d_year, amount, cnt, source FROM sales_agg
    UNION ALL
    SELECT i_category, d_year, amount, cnt, source FROM returns_agg
) combined
ORDER BY d_year DESC, amount DESC
LIMIT 100
