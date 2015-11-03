var LinkList = React.createClass({
  propTypes: {
    links: React.PropTypes.arrayOf(React.PropTypes.object)
  },

  getInitialState: function () {
    return {links: this.props.links};
  },

  componentDidUpdate: function () {
    $('#timeline_event_links').val(JSON.stringify(this.state.links));
  },

  render: function () {
    if (this.state.links.length > 0) {
      return (
        <ul className="list-group">
          { this.state.links.map(function (link, i) {
            return (<Link title={link.title} url={link.url} private={link.private} key={i}></Link>);
          })
          }
        </ul>
      )
    } else {
      return (
        <p>No links added!</p>
      )
    }
  }
});
