WITH parsed_logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint) AS wl_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
        NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE NULLIF(element_at(split(line, '|'), 2), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 5), '') IS NOT NULL
),

review_or_lookup_sales AS (
    SELECT DISTINCT
        pl.wl_id AS s_sk,
        pl.wl_timestamp AS c_date
    FROM parsed_logs pl
    JOIN iceberg.bigbenchv2_sf1.web_pages wp
      ON pl.wl_webpage_name = wp.w_web_page_name
    WHERE wp.w_web_page_type = 'product look up'
      AND CAST(pl.wl_timestamp AS date) >= DATE '2012-09-02'
      AND CAST(pl.wl_timestamp AS date) <= DATE '2013-09-02'
),

sales_in_period AS (
    SELECT
        ws.ws_quantity * i.i_price AS totalprice,
        ws.ws_transaction_id
    FROM iceberg.bigbenchv2_sf1.web_sales ws
    JOIN iceberg.bigbenchv2_sf1.items i
      ON ws.ws_item_id = i.i_item_id
    WHERE CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date) >= DATE '2012-09-02'
      AND CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date) <= DATE '2013-09-02'
),

review_sales AS (
    SELECT
        SUM(s.totalprice) AS amount
    FROM sales_in_period s
    JOIN review_or_lookup_sales r
      ON s.ws_transaction_id = r.s_sk
),

all_sales AS (
    SELECT
        SUM(totalprice) AS amount
    FROM sales_in_period
)

SELECT
    review_sales.amount AS q08_review_sales_amount,
    all_sales.amount - review_sales.amount AS no_q08_review_sales_amount
FROM review_sales
CROSS JOIN all_sales