SELECT
    d_year,
    state,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(sales_net_paid) AS total_sales_net_paid,
    SUM(return_net_loss) AS total_return_net_loss,
    SUM(return_amount) AS total_return_amount,
    SUM(return_quantity) AS total_return_quantity
FROM (
    SELECT
        d.d_year,
        s.s_state AS state,
        ss.ss_net_profit AS sales_net_profit,
        ss.ss_net_paid AS sales_net_paid,
        CAST(0 AS decimal(7,2)) AS return_net_loss,
        CAST(0 AS decimal(7,2)) AS return_amount,
        CAST(0 AS integer) AS return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        d.d_year,
        ws_site.web_state AS state,
        ws.ws_net_profit AS sales_net_profit,
        ws.ws_net_paid AS sales_net_paid,
        CAST(0 AS decimal(7,2)) AS return_net_loss,
        CAST(0 AS decimal(7,2)) AS return_amount,
        CAST(0 AS integer) AS return_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk

    UNION ALL

    SELECT
        d.d_year,
        cc.cc_state AS state,
        cs.cs_net_profit AS sales_net_profit,
        cs.cs_net_paid AS sales_net_paid,
        CAST(0 AS decimal(7,2)) AS return_net_loss,
        CAST(0 AS decimal(7,2)) AS return_amount,
        CAST(0 AS integer) AS return_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        d.d_year,
        s.s_state AS state,
        CAST(0 AS decimal(7,2)) AS sales_net_profit,
        CAST(0 AS decimal(7,2)) AS sales_net_paid,
        sr.sr_net_loss AS return_net_loss,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        d.d_year,
        ca.ca_state AS state,
        CAST(0 AS decimal(7,2)) AS sales_net_profit,
        CAST(0 AS decimal(7,2)) AS sales_net_paid,
        wr.wr_net_loss AS return_net_loss,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT
        d.d_year,
        cc.cc_state AS state,
        CAST(0 AS decimal(7,2)) AS sales_net_profit,
        CAST(0 AS decimal(7,2)) AS sales_net_paid,
        cr.cr_net_loss AS return_net_loss,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
) t
GROUP BY d_year, state
ORDER BY d_year, state
