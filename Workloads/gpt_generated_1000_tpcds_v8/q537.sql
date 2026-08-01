WITH
    -- Base sales data with deep joins to dimensions
    sales_base AS (
        SELECT
            ss.ss_ticket_number,
            d1.d_year AS sales_year,
            i.i_category AS sales_category,
            ss.ss_net_paid,
            ss.ss_net_profit
        FROM store_sales ss
        JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    ),
    -- Catalog returns joined through item, call_center, ship_mode and date_dim (full outer join to call_center)
    catalog_join AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cc.cc_name,
            sm.sm_type,
            d2.d_year AS return_year,
            i2.i_category AS return_category
        FROM catalog_returns cr
        FULL OUTER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    ),
    -- Web returns joined to item, date_dim and web_site
    web_returns_join AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_return_amt,
            wr.wr_return_tax,
            d3.d_year AS web_return_year,
            i3.i_category AS web_return_category,
            ws.web_name
        FROM web_returns wr
        JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk
        JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d3.d_date_sk
    ),
    -- Intersect ticket numbers that appear in both sales and returns
    ticket_intersect AS (
        SELECT ss_ticket_number FROM store_sales
        INTERSECT
        SELECT sr_ticket_number FROM store_returns
    ),
    -- Union of three data streams (sales, catalog returns, web returns)
    unioned AS (
        SELECT
            sb.sales_year AS year,
            sb.sales_category AS category,
            sb.ss_net_paid AS net_paid,
            sb.ss_net_profit AS net_profit
        FROM sales_base sb
        JOIN ticket_intersect ti ON sb.ss_ticket_number = ti.ss_ticket_number

        UNION DISTINCT

        SELECT
            cj.return_year AS year,
            cj.return_category AS category,
            cj.cr_return_amount AS net_paid,
            cj.cr_net_loss AS net_profit
        FROM catalog_join cj
        WHERE cj.cr_item_sk IS NOT NULL  -- keep only matched rows after full outer join

        UNION DISTINCT

        SELECT
            wrj.web_return_year AS year,
            wrj.web_return_category AS category,
            wrj.wr_return_amt AS net_paid,
            wrj.wr_return_tax AS net_profit
        FROM web_returns_join wrj
    )
SELECT
    year,
    category,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM unioned
GROUP BY ROLLUP (year, category)
ORDER BY year NULLS LAST, category
LIMIT 100
