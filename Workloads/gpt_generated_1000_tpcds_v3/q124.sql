WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        d.d_date AS d_date,
        cc.cc_division AS cc_division,
        cc.cc_division_name AS cc_division_name,
        s.s_state AS s_state,
        i.i_category AS i_category,
        ws.web_country AS web_country,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_net_loss AS wr_net_loss,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        cd.cd_gender AS cd_gender,
        ca.ca_city AS ca_city,
        c.c_birth_country AS c_birth_country
    FROM
        date_dim d
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN item i ON wr.wr_item_sk = i.i_item_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        LEFT JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
        LEFT JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_division = 4
        AND s.s_state = 'CA'
        AND i.i_category = 'Sports'
        AND inv.inv_quantity_on_hand > 100
        AND ws.web_country = 'United States'
)
SELECT
    d_year,
    d_month_seq,
    cc_division,
    cc_division_name,
    s_state,
    i_category,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_amt) AS avg_return_amount,
    SUM(wr_return_quantity) AS total_return_quantity,
    SUM(wr_net_loss) AS total_net_loss,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(*) AS return_rows
FROM base
GROUP BY
    d_year,
    d_month_seq,
    cc_division,
    cc_division_name,
    s_state,
    i_category
ORDER BY
    total_return_amount DESC
LIMIT 100
