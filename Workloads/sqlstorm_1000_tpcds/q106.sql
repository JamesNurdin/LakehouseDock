WITH sales_agg AS (
    SELECT
        year,
        country,
        SUM(net_paid) AS total_sales,
        SUM(net_profit) AS total_profit
    FROM (
        SELECT
            d.d_year AS year,
            ca.ca_country AS country,
            cs.cs_net_paid_inc_tax AS net_paid,
            cs.cs_net_profit AS net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002

        UNION ALL

        SELECT
            d.d_year,
            ca.ca_country,
            ss.ss_net_paid_inc_tax,
            ss.ss_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002

        UNION ALL

        SELECT
            d.d_year,
            ca.ca_country,
            ws.ws_net_paid_inc_tax,
            ws.ws_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002
    ) t
    GROUP BY year, country
), returns_agg AS (
    SELECT
        year,
        country,
        SUM(net_loss) AS total_returns
    FROM (
        SELECT
            d.d_year AS year,
            ca.ca_country AS country,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002

        UNION ALL

        SELECT
            d.d_year,
            ca.ca_country,
            sr.sr_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002

        UNION ALL

        SELECT
            d.d_year,
            ca.ca_country,
            wr.wr_net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Sports'
          AND d.d_year BETWEEN 1999 AND 2002
    ) t
    GROUP BY year, country
)
SELECT
    s.year,
    s.country,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_sales
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.year = r.year AND s.country = r.country
ORDER BY s.year, s.country
